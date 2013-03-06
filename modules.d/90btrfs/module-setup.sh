#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # if we don't have btrfs installed on the host system,
    # no point in trying to support it in the initramfs.
    type -P btrfs >/dev/null || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        local _found
        for fs in ${host_fs_types[@]}; do
            strstr "$fs" "\|btrfs" && _found="1"
        done
        [[ $_found ]] || return 1
        unset _found
    }

    return 0
}

depends() {
    echo udev-rules
    return 0
}

installkernel() {
    instmods btrfs
}

install() {
    if ! inst_rules 64-btrfs.rules; then
        inst_rules "$moddir/80-btrfs.rules"
        case "$(btrfs --help)" in
            *device\ ready*)
                inst_script "$moddir/btrfs_device_ready.sh" /sbin/btrfs_finished ;;
            *)
                inst_script "$moddir/btrfs_finished.sh" /sbin/btrfs_finished ;;
        esac
    fi

    if ! dracut_module_included "systemd"; then
        inst_script "$moddir/btrfs_timeout.sh" \
            /usr/lib/dracut/hooks/initqueue/timeout/btrfs_timeout.sh
    fi

    dracut_install btrfsck
    inst $(command -v btrfs) /sbin/btrfs
}

