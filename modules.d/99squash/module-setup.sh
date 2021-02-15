#!/bin/bash

check() {
    require_binaries mksquashfs unsquashfs || return 1

    for i in CONFIG_SQUASHFS CONFIG_BLK_DEV_LOOP CONFIG_OVERLAY_FS ; do
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
    local squash_candidate=( "usr" "etc" )

    # shellcheck disable=SC2174
    mkdir -m 0755 -p "$squash_dir"
    for folder in "${squash_candidate[@]}"; do
        mv "$initdir/$folder" "$squash_dir/$folder"
    done

    # Move some files out side of the squash image, including:
    # - Files required to boot and mount the squashfs image
    # - Files need to be accessible without mounting the squash image
    # - Initramfs marker
    for file in \
        "$squash_dir"/usr/lib/dracut/* \
        "$squash_dir"/etc/initrd-release
    do
        [[ -f $file ]] || continue
        DRACUT_RESOLVE_DEPS=1 dracutsysrootdir="$squash_dir" inst "${file#$squash_dir}"
        rm "$file"
    done

    # Install required files for the squash image setup script.
    inst_multiple modprobe mount mkdir ln echo rm

    mv "$initdir"/init "$initdir"/init.orig
    inst "$moddir"/init-squash.sh /init
    inst "$moddir"/clear-squash.sh /squash/clear-squash.sh

    # Keep systemctl outsite if we need switch root
    if [[ ! -f "$initdir/lib/dracut/no-switch-root" ]]; then
      inst "systemctl"
    fi

    # Remove duplicated files
    for folder in "${squash_candidate[@]}"; do
        find "$initdir/$folder/" -not -type d \
            -exec bash -c 'mv -f "$squash_dir${1#$initdir}" "$1"' -- "{}" \;
    done

    # Install required modules for the squash image init script.
    hostonly="" instmods "loop" "squashfs" "overlay"
    dracut_kernel_post
}

install() {
    if [[ $DRACUT_SQUASH_POST_INST ]]; then
        installpost
        return
    fi

    inst "$moddir/squash-mnt-clear.service" "$systemdsystemunitdir/squash-mnt-clear.service"
    $SYSTEMCTL -q --root "$initdir" add-wants initrd-switch-root.target squash-mnt-clear.service
}
