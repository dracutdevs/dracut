#!/bin/bash
# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on a ext4 filesystem"

test_check() {
    command -v systemctl &> /dev/null
}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell=1 rd.break=pre-mount"
test_run() {
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.img root

    test_marker_reset
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=LABEL=dracut rw loglevel=77 systemd.log_level=debug systemd.log_target=console rd.retry=3 rd.info console=ttyS0,115200n81 selinux=0 init=/sbin/init rd.shell=0 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing || return 1

    test_marker_check || return 1
}

test_setup() {
    # Create what will eventually be our root filesystem onto an overlay
    "$DRACUT" -l --keep --tmpdir "$TESTDIR" \
        -m "test-root" \
        -i ./test-init.sh /sbin/init \
        -i "${PKGLIBDIR}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh" \
        -i "${PKGLIBDIR}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh" \
        --no-hostonly --no-hostonly-cmdline --nomdadmconf --nohardlink \
        -f "$TESTDIR"/initramfs.root "$KVERSION" || return 1
    mkdir -p "$TESTDIR"/overlay/source && mv "$TESTDIR"/dracut.*/initramfs/* "$TESTDIR"/overlay/source && rm -rf "$TESTDIR"/dracut.*

    # second, install the files needed to make the root filesystem
    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -m "test-makeroot" \
        -I "mkfs.ext4" \
        -i ./create-root.sh /var/lib/dracut/hooks/initqueue/01-create-root.sh \
        --nomdadmconf \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker 1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.img root 80

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/fakeroot rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    test_marker_check dracut-root-block-created || return 1
    rm -- "$TESTDIR"/marker.img

    # systemd-analyze.sh calls man indirectly
    # make the man command succeed always
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -a "test systemd" \
        -o "network kernel-network-modules" \
        -d "piix ide-gd_mod ata_piix ext4 sd_mod" \
        -i ./systemd-analyze.sh /var/lib/dracut/hooks/pre-pivot/00-systemd-analyze.sh \
        -i "/bin/true" "/usr/bin/man" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
