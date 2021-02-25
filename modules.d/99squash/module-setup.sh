#!/bin/bash

check() {
    require_binaries mksquashfs unsquashfs || return 1

    for i in CONFIG_SQUASHFS CONFIG_BLK_DEV_LOOP CONFIG_OVERLAY_FS; do
        if ! check_kernel_config $i; then
            dinfo "dracut-squash module requires kernel configuration $i (y or m)"
            return 1
        fi
    done

    return 255
}

depends() {
    echo "systemd-initrd"
    return 0
}

installpost() {
    local _busybox
    _busybox=$(find_binary busybox)

    # Move everything under $initdir except $squash_dir
    # itself into squash image
    for i in "$initdir"/*; do
        [[ $squash_dir == "$i"/* ]] || mv "$i" "$squash_dir"/
    done

    # Create mount points for squash loader
    mkdir -p "$initdir"/squash/
    mkdir -p "$squash_dir"/squash/

    # Copy dracut spec files out side of the squash image
    # so dracut rebuild and lsinitrd can work
    for file in "$squash_dir"/usr/lib/dracut/*; do
        [[ -f $file ]] || continue
        DRACUT_RESOLVE_DEPS=1 dracutsysrootdir="$squash_dir" inst "${file#$squash_dir}"
    done

    # Install required modules and binaries for the squash image init script.
    if [[ $_busybox ]]; then
        inst "$_busybox" /usr/bin/busybox
        for _i in sh echo mount modprobe mkdir switch_root; do
            ln_r /usr/bin/busybox /usr/bin/$_i
        done
    else
        DRACUT_RESOLVE_DEPS=1 inst_multiple sh mount modprobe mkdir switch_root
    fi

    hostonly="" instmods "loop" "squashfs" "overlay"
    dracut_kernel_post

    # Install squash image init script.
    ln -sfn /usr/bin "$initdir/bin"
    ln -sfn /usr/sbin "$initdir/sbin"
    inst_simple "$moddir"/init-squash.sh /init
}

install() {
    if [[ $DRACUT_SQUASH_POST_INST ]]; then
        installpost
    fi
}
