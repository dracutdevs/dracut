#!/bin/bash
# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on a ext3 filesystem"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
# DEBUGFAIL="rd.shell rd.break"

test_run() {
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.img root

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -device i6300esb -watchdog-action poweroff \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot \"root=LABEL=  rdinit=/bin/sh\" rw systemd.log_level=debug systemd.log_target=console rd.retry=3 rd.debug console=ttyS0,115200n81 rd.shell=0 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing || return 1

    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success "$TESTDIR"/marker.img
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
        -m "test-makeroot dash rootfs-block kernel-modules" \
        -d "piix ide-gd_mod ata_piix ext3 sd_mod" \
        -I "mkfs.ext3" \
        -i ./create-root.sh /lib/dracut/hooks/initqueue/01-create-root.sh \
        --nomdadmconf \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    dd if=/dev/zero of="$TESTDIR"/root.img bs=1MiB count=80
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.img root

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/dracut/root rw rootfstype=ext3 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/marker.img || return 1
    rm -- "$TESTDIR"/marker.img

    # make sure --omit-drivers does not filter out drivers using regexp to test for an earlier regression (assuming there is no one letter linux kernel module needed to run the test)
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -a "test watchdog" \
        -d "piix ide-gd_mod ata_piix ext3 sd_mod i6300esb ib700wdt" \
        --omit-drivers 'a b c d e f g h i j k l m n o p q r s t u v w x y z' \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
