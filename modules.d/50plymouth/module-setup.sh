#!/bin/bash

pkglib_dir() {
    local _dirs="/usr/lib/plymouth /usr/libexec/plymouth/"
    if find_binary dpkg-architecture &> /dev/null; then
        local _arch
        _arch=$(dpkg-architecture -qDEB_HOST_MULTIARCH 2> /dev/null)
        [ -n "$_arch" ] && _dirs+=" /usr/lib/$_arch/plymouth"
    fi
    for _dir in $_dirs; do
        if [ -x "$dracutsysrootdir""$_dir"/plymouth-populate-initrd ]; then
            echo "$_dir"
            return
        fi
    done
}

# called by dracut
check() {
    [[ "$mount_needs" ]] && return 1
    [[ $(pkglib_dir) ]] || return 1

    require_binaries plymouthd plymouth plymouth-set-default-theme || return 1

    return 0
}

# called by dracut
depends() {
    echo drm
}

# called by dracut
install() {
    PKGLIBDIR=$(pkglib_dir)
    if grep -q nash "$dracutsysrootdir""${PKGLIBDIR}"/plymouth-populate-initrd \
        || [ ! -x "$dracutsysrootdir""${PKGLIBDIR}"/plymouth-populate-initrd ]; then
        # shellcheck disable=SC1090
        . "$moddir"/plymouth-populate-initrd.sh
    else
        PLYMOUTH_POPULATE_SOURCE_FUNCTIONS="$dracutfunctions" \
            "$dracutsysrootdir""${PKGLIBDIR}"/plymouth-populate-initrd -t "$initdir"
    fi

    inst_hook emergency 50 "$moddir"/plymouth-emergency.sh

    inst_multiple readlink

    inst_multiple plymouthd plymouth plymouth-set-default-theme

    if ! dracut_module_included "systemd"; then
        inst_hook pre-trigger 10 "$moddir"/plymouth-pretrigger.sh
        inst_hook pre-pivot 90 "$moddir"/plymouth-newroot.sh
    fi
}
