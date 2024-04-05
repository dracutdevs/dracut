#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on a btrfs filesystem with /usr subvolume"

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"

client_run() {
    local test_name="$1"
    shift
    local client_opts="$*"

    echo "CLIENT TEST START: $test_name"

    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.btrfs root
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/usr.btrfs usr

    test_marker_reset
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -device i6300esb -watchdog-action poweroff \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=LABEL=dracut $client_opts loglevel=7 rd.retry=3 rd.info console=ttyS0,115200n81 selinux=0 rd.debug rd.shell=0 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing || return 1

    if ! test_marker_check; then
        echo "CLIENT TEST END: $test_name [FAILED]"
        return 1
    fi
    echo "CLIENT TEST END: $test_name [OK]"
}

test_run() {
    client_run "no option specified" || return 1
    client_run "readonly root" "ro" || return 1
    client_run "writeable root" "rw" || return 1
}

test_setup() {
    # Create what will eventually be our root filesystem onto an overlay
    "$DRACUT" -l --keep --tmpdir "$TESTDIR" \
        -m "test-root" \
        -i ./test-init.sh /sbin/init \
        -i ./fstab /etc/fstab \
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
        -I "mkfs.btrfs" \
        -i ./create-root.sh /var/lib/dracut/hooks/initqueue/01-create-root.sh \
        --nomdadmconf \
        --nohardlink \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    # Create the blank file to use as a root filesystem
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker 1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.btrfs root 160
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/usr.btrfs usr 160

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/dracut/root rw rootfstype=btrfs quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1

    if ! test_marker_check dracut-root-block-created; then
        echo "Could not create root filesystem"
        return 1
    fi

    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -a "test watchdog" \
        -o "network kernel-network-modules" \
        -d "piix ide-gd_mod ata_piix btrfs sd_mod i6300esb ib700wdt" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
