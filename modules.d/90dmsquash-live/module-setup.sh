#!/bin/bash

# called by dracut
check() {
    # a live host-only image doesn't really make a lot of sense
    [[ $hostonly ]] && return 1
    return 255
}

# called by dracut
depends() {
    # if dmsetup is not installed, then we cannot support fedora/red hat
    # style live images
    echo dm rootfs-block img-lib overlayfs
    return 0
}

# called by dracut
installkernel() {
    instmods squashfs loop iso9660
}

# called by dracut
install() {
    inst_multiple umount dmsetup blkid dd losetup blockdev find rmdir grep
    inst_multiple -o checkisomd5
    inst_hook cmdline 30 "$moddir/parse-dmsquash-live.sh"
    inst_hook cmdline 31 "$moddir/parse-iso-scan.sh"
    inst_hook pre-udev 30 "$moddir/dmsquash-live-genrules.sh"
    inst_hook pre-udev 30 "$moddir/dmsquash-liveiso-genrules.sh"
    inst_hook pre-pivot 20 "$moddir/apply-live-updates.sh"
    inst_script "$moddir/dmsquash-live-root.sh" "/sbin/dmsquash-live-root"
    inst_script "$moddir/iso-scan.sh" "/sbin/iso-scan"
    if dracut_module_included "systemd-initrd"; then
        inst_script "$moddir/dmsquash-generator.sh" "$systemdutildir"/system-generators/dracut-dmsquash-generator
        inst_simple "$moddir/checkisomd5@.service" "/etc/systemd/system/checkisomd5@.service"
    fi
    dracut_need_initqueue
}
