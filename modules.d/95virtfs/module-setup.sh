#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ "$fs" == "9p" ]] && return 0
        done
        return 255
    }

    if type -P systemd-detect-virt >/dev/null 2>&1; then
        vm=$(systemd-detect-virt --vm >/dev/null 2>&1)
        (($? != 0)) && return 255
        [[ $vm = "qemu" ]] && return 0
        [[ $vm = "kvm" ]] && return 0
        [[ $vm = "bochs" ]] && return 0
    fi

    for i in /sys/class/dmi/id/*_vendor; do
        [[ -f $i ]] || continue
        read vendor < $i
        [[  "$vendor" == "QEMU" ]] && return 0
        [[  "$vendor" == "Bochs" ]] && return 0
    done
    return 255
}

depends() {
    return 0
}

installkernel() {
    instmods 9p 9pnet_virtio virtio_pci
}

install() {
    inst_hook cmdline 95 "$moddir/parse-virtfs.sh"

    if ! dracut_module_included "systemd"; then
        inst_hook mount 99 "$moddir/mount-virtfs.sh"
    else
        inst_script "$moddir/virtfs-generator.sh" $systemdutildir/system-generators/dracut-virtfs-generator
    fi
}
