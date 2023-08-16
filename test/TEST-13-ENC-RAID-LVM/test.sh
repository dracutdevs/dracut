#!/bin/bash
# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on LVM on encrypted partitions of a RAID-5"

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break" # udev.log-priority=debug
#DEBUGFAIL="rd.shell rd.udev.log-priority=debug loglevel=70 systemd.log_target=kmsg systemd.log_target=debug"
#DEBUGFAIL="rd.shell loglevel=70 systemd.log_target=kmsg systemd.log_target=debug"

test_run() {
    LUKSARGS=$(cat "$TESTDIR"/luks.txt)

    echo "CLIENT TEST START: $LUKSARGS"

    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-1.img disk1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-2.img disk2
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-3.img disk3

    test_marker_reset
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=/dev/dracut/root rw rd.auto rd.retry=20 console=ttyS0,115200n81 selinux=0 rd.debug rootwait $LUKSARGS rd.shell=0 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing
    test_marker_check || return 1
    echo "CLIENT TEST END: [OK]"

    test_marker_reset

    echo "CLIENT TEST START: Any LUKS"
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=/dev/dracut/root rw quiet rd.auto rd.retry=20 rd.info console=ttyS0,115200n81 selinux=0 rd.debug  $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing
    test_marker_check || return 1
    echo "CLIENT TEST END: [OK]"

    test_marker_reset

    echo "CLIENT TEST START: Wrong LUKS UUID"
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=/dev/dracut/root rw quiet rd.auto rd.retry=10 rd.info console=ttyS0,115200n81 selinux=0 rd.debug  $DEBUGFAIL rd.luks.uuid=failme" \
        -initrd "$TESTDIR"/initramfs.testing
    test_marker_check && return 1
    echo "CLIENT TEST END: [OK]"

    return 0
}

test_setup() {
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
            mount dmesg mkdir cp dd
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
        inst_simple /etc/os-release
        inst ./test-init.sh /sbin/init
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
        inst_multiple sfdisk mkfs.ext4 poweroff cp umount grep dd sync
        inst_hook initqueue 01 ./create-root.sh
        inst_hook initqueue/finished 01 ./finished-false.sh
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -m "bash crypt lvm mdraid kernel-modules qemu" \
        -d "piix ide-gd_mod ata_piix ext4 sd_mod" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    # Create the blank files to use as a root filesystem
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker 1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-1.img disk1 40
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-2.img disk2 40
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-3.img disk3 40

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/fakeroot rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    test_marker_check dracut-root-block-created || return 1
    cryptoUUIDS=$(grep -F --binary-files=text -m 3 ID_FS_UUID "$TESTDIR"/marker.img)
    for uuid in $cryptoUUIDS; do
        eval "$uuid"
        printf ' rd.luks.uuid=luks-%s ' "$ID_FS_UUID"
    done > "$TESTDIR"/luks.txt

    (
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$PKGLIBDIR"/dracut-init.sh
        inst_multiple poweroff shutdown dd
        inst_hook shutdown-emergency 000 ./hard-off.sh
        inst_hook emergency 000 ./hard-off.sh
        inst ./cryptroot-ask.sh /sbin/cryptroot-ask
        mkdir -p "$initdir"/etc
        i=1
        for uuid in $cryptoUUIDS; do
            eval "$uuid"
            printf 'luks-%s /dev/disk/by-id/ata-disk_disk%s /etc/key timeout=0\n' "$ID_FS_UUID" $i
            ((i += 1))
        done > "$initdir"/etc/crypttab
        echo -n test > "$initdir"/etc/key
        chmod 0600 "$initdir"/etc/key
    )
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -o "plymouth network kernel-network-modules" \
        -a "debug" \
        -d "piix ide-gd_mod ata_piix ext4 sd_mod" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
