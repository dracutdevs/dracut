#!/bin/bash

# called by dracut
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

# called by dracut
depends() {
    return 0
}

# called by dracut
installkernel() {
    instmods 9p 9pnet_virtio virtio_pci
}

# called by dracut
install() {
    inst_hook cmdline 95 "$moddir/parse-virtfs.sh"
    inst_hook mount 99 "$moddir/mount-virtfs.sh"
}
