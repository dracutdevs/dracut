#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="live root on a squash filesystem"

KVERSION="${KVERSION-$(uname -r)}"

# Uncomment these to debug failures
#DEBUGFAIL="rd.shell rd.debug rd.live.debug loglevel=7"

test_run() {
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.img root

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -boot order=d \
        -append "rd.live.overlay.overlayfs=1 root=LABEL=dracut console=ttyS0,115200n81 quiet selinux=0 rd.info rd.shell=0 panic=1 oops=panic softlockup_panic=1 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -boot order=d \
        -append "rd.live.image rd.live.overlay.overlayfs=1 root=LABEL=dracut console=ttyS0,115200n81 quiet selinux=0 rd.info rd.shell=0 panic=1 oops=panic softlockup_panic=1 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -boot order=d \
        -append "rd.live.image rd.live.overlay.overlayfs=1 rd.live.dir=testdir root=LABEL=dracut console=ttyS0,115200n81 quiet selinux=0 rd.info rd.shell=0 panic=1 oops=panic softlockup_panic=1 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing

    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

    rootPartitions=$(sfdisk -d "$TESTDIR"/root.img | grep -c 'root\.img[0-9]')
    [ "$rootPartitions" -eq 1 ] || return 1

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -boot order=d \
        -append "rd.live.image rd.live.overlay.overlayfs=1 rd.live.overlay=LABEL=persist rd.live.dir=testdir root=LABEL=dracut console=ttyS0,115200n81 quiet selinux=0 rd.info rd.shell=0 panic=1 oops=panic softlockup_panic=1 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing-autooverlay

    rootPartitions=$(sfdisk -d "$TESTDIR"/root.img | grep -c 'root\.img[0-9]')
    [ "$rootPartitions" -eq 2 ] || return 1

    (
        # Ensure that this test works when run with the `V=1` parameter, which runs the script with `set -o pipefail`.
        set +o pipefail

        # Verify that the string "dracut-autooverlay-success" occurs in the second partition in the image file.
        dd if="$TESTDIR"/root.img bs=1MiB skip=80 status=none \
            | grep -U --binary-files=binary -F -m 1 -q dracut-autooverlay-success
    ) || return 1
}

test_setup() {
    # Create what will eventually be our root filesystem onto an overlay
    "$basedir"/dracut.sh -l --keep --tmpdir "$TESTDIR" \
        -m "test-root" \
        -i ./test-init.sh /sbin/init \
        -i "${basedir}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh" \
        -i "${basedir}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh" \
        --no-hostonly --no-hostonly-cmdline --nomdadmconf --nohardlink \
        -f "$TESTDIR"/initramfs.root "$KVERSION" || return 1
    mkdir -p "$TESTDIR"/overlay/source && mv "$TESTDIR"/dracut.*/initramfs/* "$TESTDIR"/overlay/source && rm -rf "$TESTDIR"/dracut.*

    # second, install the files needed to make the root filesystem
    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        --modules "test-makeroot rootfs-block qemu" \
        --drivers "ext4 sd_mod" \
        --install "sfdisk mkfs.ext4 mksquashfs" \
        --include ./create-root.sh /lib/dracut/hooks/initqueue/01-create-root.sh \
        --no-hostonly --no-hostonly-cmdline --no-early-microcode --nofscks --nomdadmconf --nohardlink --nostrip \
        --force "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    # Create the blank file to use as a root filesystem
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    dd if=/dev/zero of="$TESTDIR"/root.img bs=1MiB count=160
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.img root

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/dracut/root rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1

    if ! grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/marker.img; then
        echo "Could not create root filesystem"
        return 1
    fi

    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        --modules "test dash dmsquash-live qemu" \
        --omit "rngd" \
        --drivers "ext4 sd_mod" \
        --install "mkfs.ext4" \
        --no-hostonly --no-hostonly-cmdline \
        --force "$TESTDIR"/initramfs.testing "$KVERSION" || return 1

    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        --modules "test dmsquash-live-autooverlay qemu" \
        --omit "rngd" \
        --drivers "ext4 sd_mod" \
        --install "mkfs.ext4" \
        --no-hostonly --no-hostonly-cmdline \
        --force "$TESTDIR"/initramfs.testing-autooverlay "$KVERSION" || return 1

    rm -rf -- "$TESTDIR"/overlay
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
