#!/bin/bash

# called by dracut
check() {
    return 0
}

# called by dracut
depends() {
    echo base fs-lib
}

cmdline_journal() {
    if [[ $hostonly ]]; then
        for dev in "${!host_fs_types[@]}"; do
            [[ ${host_fs_types[$dev]} == "reiserfs" ]] || [[ ${host_fs_types[$dev]} == "xfs" ]] || continue
            rootopts=$(find_dev_fsopts "$dev")
            if [[ ${host_fs_types[$dev]} == "reiserfs" ]]; then
                journaldev=$(fs_get_option "$rootopts" "jdev")
            elif [[ ${host_fs_types[$dev]} == "xfs" ]]; then
                journaldev=$(fs_get_option "$rootopts" "logdev")
            fi

            if [ -n "$journaldev" ]; then
                printf " root.journaldev=%s" "$journaldev"
            fi
        done
    fi
    return 0
}

cmdline_rootfs() {
    local _block
    _block=$(find_root_block_device)
    local _dev=/dev/block/$_block
    local _fstype _flags _subvol

    # "--no-hostonly-default-device" can result in empty root_devs
    if [ "${#root_devs[@]}" -eq 0 ]; then
        return
    fi

    if [ -n "$_block" -a -b "$_dev" ]; then
        printf " root=%s" "$(shorten_persistent_dev "$(get_persistent_dev "$_dev")")"
    fi
    _fstype="$(find_mp_fstype /)"
    if [[ ${_fstype} == "zfs" ]]; then
        local _root_ds
        _root_ds="$(findmnt -n -o SOURCE /)"
        printf " root=zfs:%s" "${_root_ds// /+}"
    fi
    _flags="$(find_mp_fsopts /)"
    if [ -n "$_fstype" ]; then
        printf " rootfstype=%s" "$_fstype"
    fi
    if [[ $use_fstab != yes ]] && [[ $_fstype == btrfs ]]; then
        _subvol=$(findmnt -e -v -n -o FSROOT --target /) \
            && _subvol=${_subvol#/}
        _flags="$_flags${_subvol:+,subvol=$_subvol}"
    fi
    if [ -n "$_flags" ]; then
        printf " rootflags=%s" "$_flags"
    fi
}

# called by dracut
cmdline() {
    cmdline_rootfs
    cmdline_journal
}

# called by dracut
install() {
    if [[ $hostonly_cmdline == "yes" ]]; then
        local _journaldev
        _journaldev=$(cmdline_journal)
        [[ $_journaldev ]] && printf "%s\n" "$_journaldev" >> "${initdir}/etc/cmdline.d/95root-journaldev.conf"
        local _rootdev
        _rootdev=$(cmdline_rootfs)
        [[ $_rootdev ]] && printf "%s\n" "$_rootdev" >> "${initdir}/etc/cmdline.d/95root-dev.conf"
    fi

    inst_multiple umount
    inst_multiple tr
    if ! dracut_module_included "systemd"; then
        inst_hook cmdline 95 "$moddir/parse-block.sh"
        inst_hook pre-udev 30 "$moddir/block-genrules.sh"
        inst_hook mount 99 "$moddir/mount-root.sh"
    fi

    inst_hook initqueue/timeout 99 "$moddir/rootfallback.sh"
}
