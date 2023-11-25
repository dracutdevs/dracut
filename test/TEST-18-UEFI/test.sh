#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="UEFI boot"

# Linux kernel requirements
# CONFIG_BLK_DEV_INITRD for initramfs
# CONFIG_EFI_HANDOVER_PROTOCOL for ovmf (Open Virtual Machine Firmware)
# CONFIG_SATA_AHCI for ahci.ko
# CONFIG_BLK_DEV_SD for sd_mod.ko
# CONFIG_SQUASHFS_ZLIB for squashfs.ko

ovmf_code() {
    for path in \
        "/usr/share/OVMF/OVMF_CODE.fd" \
        "/usr/share/edk2/x64/OVMF_CODE.fd" \
        "/usr/share/edk2-ovmf/OVMF_CODE.fd" \
        "/usr/share/qemu/ovmf-x86_64-4m.bin"; do
        [[ -s $path ]] && echo -n "$path" && return
    done
}

test_check() {
    [[ -n "$(ovmf_code)" ]]
}

KVERSION="${KVERSION-$(uname -r)}"

test_marker_reset() {
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
}

test_marker_check() {
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img
    return $?
}

test_dracut() {
    TEST_DRACUT_ARGS+=" --local --no-hostonly --no-early-microcode --add test --kver $KVERSION"

    # shellcheck disable=SC2162
    IFS=' ' read -a TEST_DRACUT_ARGS_ARRAY <<< "$TEST_DRACUT_ARGS"

    "$DRACUT" "$@" \
        --kernel-cmdline "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot selinux=0 console=ttyS0,115200n81 $DEBUGFAIL" \
        "${TEST_DRACUT_ARGS_ARRAY[@]}" || return 1
}

test_run() {
    declare -a disk_args=()
    declare -i disk_index=1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/squashfs.img root

    test_marker_reset
    "$testdir"/run-qemu "${disk_args[@]}" -net none \
        -drive file=fat:rw:"$TESTDIR"/ESP,format=vvfat,label=EFI \
        -global driver=cfi.pflash01,property=secure,value=on \
        -drive if=pflash,format=raw,unit=0,file="$(ovmf_code)",readonly=on
    test_marker_check || return 1
}

test_setup() {
    # Create what will eventually be our root filesystem
    "$DRACUT" --local --no-hostonly --no-early-microcode --nofscks \
        --tmpdir "$TESTDIR" --keep --modules "test-root" --include ./test-init.sh /sbin/init \
        "$TESTDIR"/tmp-initramfs.root "$KVERSION" || return 1

    mkdir -p "$TESTDIR"/dracut.*/initramfs/proc
    mksquashfs "$TESTDIR"/dracut.*/initramfs/ "$TESTDIR"/squashfs.img -quiet -no-progress

    mkdir -p "$TESTDIR"/ESP/EFI/BOOT

    if [ -f "/usr/lib/gummiboot/linuxx64.efi.stub" ]; then
        TEST_DRACUT_ARGS+=" --uefi-stub /usr/lib/gummiboot/linuxx64.efi.stub "
    fi

    mkdir -p "$TESTDIR"/ESP/EFI/BOOT
    test_dracut \
        --modules 'rootfs-block test' \
        --kernel-cmdline 'root=/dev/disk/by-id/ata-disk_root ro rd.skipfsck rootfstype=squashfs' \
        --drivers 'ahci sd_mod squashfs' \
        --uefi \
        "$TESTDIR"/ESP/EFI/BOOT/BOOTX64.efi
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
