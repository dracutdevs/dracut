#!/bin/bash
# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on an encrypted LVM PV on a degraded RAID-5"

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break rd.debug"
#DEBUGFAIL="rd.shell rd.break=pre-mount udev.log-priority=debug"
#DEBUGFAIL="rd.shell rd.udev.log-priority=debug loglevel=70 systemd.log_target=kmsg"
#DEBUGFAIL="rd.shell loglevel=70 systemd.log_target=kmsg"

client_run() {
    echo "CLIENT TEST START: $*"
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    # degrade the RAID
    # qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-1.img raid1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-2.img raid2
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-3.img raid3

    test_marker_reset
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot $* systemd.log_target=kmsg root=LABEL=root rw rd.retry=10 rd.info console=ttyS0,115200n81 log_buf_len=2M selinux=0 rd.shell=0 $DEBUGFAIL " \
        -initrd "$TESTDIR"/initramfs.testing

    if ! test_marker_check; then
        echo "CLIENT TEST END: $* [FAIL]"
        return 1
    fi

    echo "CLIENT TEST END: $* [OK]"
    return 0
}

test_run() {
    read -r LUKS_UUID < "$TESTDIR"/luksuuid
    read -r MD_UUID < "$TESTDIR"/mduuid

    client_run failme && return 1
    client_run rd.auto || return 1

    client_run rd.luks.uuid="$LUKS_UUID" rd.md.uuid="$MD_UUID" rd.md.conf=0 rd.lvm.vg=dracut || return 1

    client_run rd.luks.uuid="$LUKS_UUID" rd.md.uuid=failme rd.md.conf=0 rd.lvm.vg=dracut failme && return 1

    client_run rd.luks.uuid="$LUKS_UUID" rd.md.uuid="$MD_UUID" rd.lvm=0 failme && return 1
    client_run rd.luks.uuid="$LUKS_UUID" rd.md.uuid="$MD_UUID" rd.lvm=0 rd.auto=1 failme && return 1
    client_run rd.luks.uuid="$LUKS_UUID" rd.md.uuid="$MD_UUID" rd.lvm.vg=failme failme && return 1
    client_run rd.luks.uuid="$LUKS_UUID" rd.md.uuid="$MD_UUID" rd.lvm.vg=dracut || return 1
    client_run rd.luks.uuid="$LUKS_UUID" rd.md.uuid="$MD_UUID" rd.lvm.lv=dracut/failme failme && return 1
    client_run rd.luks.uuid="$LUKS_UUID" rd.md.uuid="$MD_UUID" rd.lvm.lv=dracut/root || return 1

    return 0
}

test_setup() {
    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
        # shellcheck disable=SC2030
        export initdir=$TESTDIR/overlay/source
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        (
            cd "$initdir" || exit
            mkdir -p -- dev sys proc etc var/run tmp
            mkdir -p root usr/bin usr/lib usr/lib64 usr/sbin
        )
        inst_multiple sh df free ls shutdown poweroff stty cat ps ln \
            mount dmesg mkdir cp dd sync
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux

        inst_simple "${basedir}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh"
        inst_simple "${basedir}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh"
        inst_binary "${basedir}/dracut-util" "/usr/bin/dracut-util"
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
        # shellcheck disable=SC2030
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        inst_multiple sfdisk mkfs.ext4 poweroff cp umount dd grep sync
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
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-1.img raid1 40
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-2.img raid2 40
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-3.img raid3 40

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/fakeroot rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1

    test_marker_check dracut-root-block-created || return 1
    eval "$(grep -F --binary-files=text -m 1 MD_UUID "$TESTDIR"/marker.img)"
    eval "$(grep -F -a -m 1 ID_FS_UUID "$TESTDIR"/marker.img)"
    echo "$ID_FS_UUID" > "$TESTDIR"/luksuuid
    eval "$(grep -F --binary-files=text -m 1 MD_UUID "$TESTDIR"/marker.img)"
    echo "$MD_UUID" > "$TESTDIR"/mduuid

    (
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        inst_multiple poweroff shutdown dd
        inst_hook shutdown-emergency 000 ./hard-off.sh
        inst_hook emergency 000 ./hard-off.sh
        inst ./cryptroot-ask.sh /sbin/cryptroot-ask
        mkdir -p "$initdir"/etc
        echo "ARRAY /dev/md0 level=raid5 num-devices=3 UUID=$MD_UUID" > "$initdir"/etc/mdadm.conf
        echo "luks-$ID_FS_UUID UUID=$ID_FS_UUID /etc/key" > "$initdir"/etc/crypttab
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
