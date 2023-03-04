#!/bin/bash
# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on an encrypted LVM PV on a degraded RAID-5"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break rd.debug"
#DEBUGFAIL="rd.shell rd.break=pre-mount udev.log-priority=debug"
#DEBUGFAIL="rd.shell rd.udev.log-priority=debug loglevel=70 systemd.log_target=kmsg"
#DEBUGFAIL="rd.shell loglevel=70 systemd.log_target=kmsg"

client_run() {
    echo "CLIENT TEST START: $*"
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    # degrade the RAID
    # qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-1.img raid1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-2.img raid2
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-3.img raid3

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot $* systemd.log_target=kmsg root=LABEL=root rw rd.retry=10 rd.info console=ttyS0,115200n81 log_buf_len=2M selinux=0 rd.shell=0 $DEBUGFAIL " \
        -initrd "$TESTDIR"/initramfs.testing

    if ! grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success "$TESTDIR"/marker.img; then
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
    "$basedir"/dracut.sh -l --keep --tmpdir "$TESTDIR" \
        -m "test-root" \
        -i ./test-init.sh /sbin/init \
        -i "${basedir}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh" \
        -i "${basedir}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh" \
        --no-hostonly --no-hostonly-cmdline --nohardlink \
        -f "$TESTDIR"/initramfs.root "$KVERSION" || return 1
    mkdir -p "$TESTDIR"/overlay/source && mv "$TESTDIR"/dracut.*/initramfs/* "$TESTDIR"/overlay/source && rm -rf "$TESTDIR"/dracut.*

    # second, install the files needed to make the root filesystem
    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -m "test-makeroot bash crypt lvm mdraid kernel-modules" \
        -d "piix ide-gd_mod ata_piix ext4 sd_mod" \
        -I "mkfs.ext4 grep sfdisk" \
        -i ./create-root.sh /lib/dracut/hooks/initqueue/01-create-root.sh \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    # Create the blank files to use as a root filesystem
    dd if=/dev/zero of="$TESTDIR"/raid-1.img bs=1MiB count=40
    dd if=/dev/zero of="$TESTDIR"/raid-2.img bs=1MiB count=40
    dd if=/dev/zero of="$TESTDIR"/raid-3.img bs=1MiB count=40
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-1.img raid1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-2.img raid2
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid-3.img raid3

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/fakeroot rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1

    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/marker.img || return 1
    eval "$(grep -F --binary-files=text -m 1 MD_UUID "$TESTDIR"/marker.img)"
    eval "$(grep -F -a -m 1 ID_FS_UUID "$TESTDIR"/marker.img)"
    echo "$ID_FS_UUID" > "$TESTDIR"/luksuuid
    eval "$(grep -F --binary-files=text -m 1 MD_UUID "$TESTDIR"/marker.img)"
    echo "$MD_UUID" > "$TESTDIR"/mduuid

    echo "ARRAY /dev/md0 level=raid5 num-devices=3 UUID=$MD_UUID" > /tmp/mdadm.conf
    echo "luks-$ID_FS_UUID UUID=$ID_FS_UUID /etc/key" > /tmp/crypttab
    echo -n test > /tmp/key
    chmod 0600 /tmp/key

    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -o "plymouth network kernel-network-modules" \
        -a "test" \
        -d "piix ide-gd_mod ata_piix ext4 sd_mod" \
        -i "./cryptroot-ask.sh" "/sbin/cryptroot-ask" \
        -i "/tmp/mdadm.conf" "/etc/mdadm.conf" \
        -i "/tmp/crypttab" "/etc/crypttab" \
        -i "/tmp/key" "/etc/key" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
