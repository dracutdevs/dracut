#!/usr/bin/bash

# called by dracut
check() {
    [[ $hostonly ]] || [[ $mount_needs ]] && {
        is_qemu_virtualized && return 0

        for fs in "${host_fs_types[@]}"; do
            [[ $fs == "virtiofs" ]] && return 0
        done
        return 255
    }

    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
installkernel() {
    instmods virtiofs
}

# called by dracut
install() {
    inst_hook cmdline 95 "$moddir/parse-virtiofs.sh"
    inst_hook pre-mount 99 "$moddir/mount-virtiofs.sh"
}
