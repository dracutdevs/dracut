#!/bin/bash
# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on multiple device btrfs"

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell"
test_run() {
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-1.img raid1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-2.img raid2
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-3.img raid3
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-4.img raid4

    test_marker_reset
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=LABEL=root rw rd.retry=3 rd.info console=ttyS0,115200n81 selinux=0 rd.shell=0 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing
    test_marker_check || return 1
}

test_setup() {
    # Create the blank file to use as a root filesystem
    DISKIMAGE=$TESTDIR/TEST-15-BTRFSRAID-root.img
    rm -f -- "$DISKIMAGE"
    dd if=/dev/zero of="$DISKIMAGE" bs=1M count=1024

    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
        # shellcheck disable=SC2030
        export initdir=$TESTDIR/overlay/source
        # shellcheck disable=SC1090
        . "$PKGLIBDIR"/dracut-init.sh
        (
            cd "$initdir" || exit
            mkdir -p -- dev sys proc etc var/run tmp
            mkdir -p root usr/bin usr/lib usr/lib64 usr/sbin
        )
        inst_multiple sh df free ls shutdown poweroff stty cat ps ln \
            mount dmesg mkdir cp sync dd
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux

        inst_simple "${PKGLIBDIR}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh"
        inst_simple "${PKGLIBDIR}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh"
        inst_binary "${PKGLIBDIR}/dracut-util" "/usr/bin/dracut-util"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getarg"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getargs"

        inst_multiple grep
        inst ./test-init.sh /sbin/init
        inst_simple /etc/os-release
        find_binary plymouth > /dev/null && inst_multiple plymouth
        cp -a /etc/ld.so.conf* "$initdir"/etc
        ldconfig -r "$initdir"
    )

    # second, install the files needed to make the root filesystem
    (
        # shellcheck disable=SC2031
        # shellcheck disable=SC2030
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$PKGLIBDIR"/dracut-init.sh
        inst_multiple sfdisk mkfs.btrfs poweroff cp umount dd sync
        inst_hook initqueue 01 ./create-root.sh
        inst_hook initqueue/finished 01 ./finished-false.sh
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -m "bash btrfs rootfs-block kernel-modules qemu" \
        -d "piix ide-gd_mod ata_piix btrfs sd_mod" \
        --nomdadmconf \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1

    rm -rf -- "$TESTDIR"/overlay

    # Create the blank files to use as a root filesystem
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker 1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-1.img raid1 150
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-2.img raid2 150
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-3.img raid3 150
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-4.img raid4 150

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/fakeroot rw quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1

    test_marker_check dracut-root-block-created || return 1

    (
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$PKGLIBDIR"/dracut-init.sh
        inst_multiple poweroff shutdown
        inst_hook shutdown-emergency 000 ./hard-off.sh
        inst_hook emergency 000 ./hard-off.sh
    )
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -o "plymouth network kernel-network-modules" \
        -a "debug" \
        -d "piix ide-gd_mod ata_piix btrfs sd_mod" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
