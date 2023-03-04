#!/bin/bash
# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on LVM on encrypted partitions of a RAID-5"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break" # udev.log-priority=debug
#DEBUGFAIL="rd.shell rd.udev.log-priority=debug loglevel=70 systemd.log_target=kmsg systemd.log_target=debug"
#DEBUGFAIL="rd.shell loglevel=70 systemd.log_target=kmsg systemd.log_target=debug"

test_run() {
    LUKSARGS=$(cat "$TESTDIR"/luks.txt)

    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1

    echo "CLIENT TEST START: $LUKSARGS"

    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-1.img disk1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-2.img disk2
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-3.img disk3

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=/dev/dracut/root rw rd.auto rd.retry=20 console=ttyS0,115200n81 selinux=0 rd.debug rootwait $LUKSARGS rd.shell=0 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success "$TESTDIR"/marker.img || return 1
    echo "CLIENT TEST END: [OK]"

    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1

    echo "CLIENT TEST START: Any LUKS"
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=/dev/dracut/root rw quiet rd.auto rd.retry=20 rd.info console=ttyS0,115200n81 selinux=0 rd.debug  $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success "$TESTDIR"/marker.img || return 1
    echo "CLIENT TEST END: [OK]"

    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1

    echo "CLIENT TEST START: Wrong LUKS UUID"
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=/dev/dracut/root rw quiet rd.auto rd.retry=10 rd.info console=ttyS0,115200n81 selinux=0 rd.debug  $DEBUGFAIL rd.luks.uuid=failme" \
        -initrd "$TESTDIR"/initramfs.testing
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success "$TESTDIR"/marker.img && return 1
    echo "CLIENT TEST END: [OK]"

    return 0
}

test_setup() {
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
        -I "mkfs.ext4 grep" \
        -i ./create-root.sh /lib/dracut/hooks/initqueue/01-create-root.sh \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    # Create the blank files to use as a root filesystem
    dd if=/dev/zero of="$TESTDIR"/disk-1.img bs=2MiB count=40
    dd if=/dev/zero of="$TESTDIR"/disk-2.img bs=2MiB count=40
    dd if=/dev/zero of="$TESTDIR"/disk-3.img bs=2MiB count=40
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-1.img disk1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-2.img disk2
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/disk-3.img disk3

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/fakeroot rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/marker.img || return 1
    cryptoUUIDS=$(grep -F --binary-files=text -m 3 ID_FS_UUID "$TESTDIR"/marker.img)
    for uuid in $cryptoUUIDS; do
        eval "$uuid"
        printf ' rd.luks.uuid=luks-%s ' "$ID_FS_UUID"
    done > "$TESTDIR"/luks.txt

    i=1
    for uuid in $cryptoUUIDS; do
        eval "$uuid"
        printf 'luks-%s /dev/disk/by-id/ata-disk_disk%s /etc/key timeout=0\n' "$ID_FS_UUID" $i
        ((i += 1))
    done > /tmp/crypttab
    echo -n test > /tmp/key
    chmod 0600 /tmp/key

    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -o "plymouth network kernel-network-modules" \
        -a "test" \
        -d "piix ide-gd_mod ata_piix ext4 sd_mod" \
        -i "./cryptroot-ask.sh" "/sbin/cryptroot-ask" \
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
