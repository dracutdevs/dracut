#!/bin/bash

# called by dracut
check() {
    [[ $mount_needs ]] && return 1

    if ! dracut_module_included "systemd"; then
        derror "systemd-initrd needs systemd in the initramfs"
        return 1
    fi

    return 0
}

# called by dracut
depends() {
    echo "systemd"
}

installkernel() {
    return 0
}

# called by dracut
install() {
    local _mods

    inst_multiple -o \
        $systemdsystemunitdir/initrd.target \
        $systemdsystemunitdir/initrd-fs.target \
        $systemdsystemunitdir/initrd-root-device.target \
        $systemdsystemunitdir/initrd-root-fs.target \
        $systemdsystemunitdir/initrd-switch-root.target \
        $systemdsystemunitdir/initrd-switch-root.service \
        $systemdsystemunitdir/initrd-cleanup.service \
        $systemdsystemunitdir/initrd-udevadm-cleanup-db.service \
        $systemdsystemunitdir/initrd-parse-etc.service

    ln_r "${systemdsystemunitdir}/initrd.target" "${systemdsystemunitdir}/default.target"

    if [ -e /etc/os-release ]; then
        . /etc/os-release
        VERSION+=" "
        PRETTY_NAME+=" "
    else
        VERSION=""
        PRETTY_NAME=""
    fi
    NAME=dracut
    ID=dracut
    VERSION+="dracut-$DRACUT_VERSION"
    PRETTY_NAME+="dracut-$DRACUT_VERSION (Initramfs)"
    VERSION_ID=$DRACUT_VERSION
    ANSI_COLOR="0;34"

    {
        echo NAME=\"$NAME\"
        echo VERSION=\"$VERSION\"
        echo ID=$ID
        echo VERSION_ID=$VERSION_ID
        echo PRETTY_NAME=\"$PRETTY_NAME\"
        echo ANSI_COLOR=\"$ANSI_COLOR\"
    } > $initdir/usr/lib/initrd-release
    echo dracut-$DRACUT_VERSION > $initdir/lib/dracut/dracut-$DRACUT_VERSION
    ln -sf ../usr/lib/initrd-release $initdir/etc/initrd-release
    ln -sf initrd-release $initdir/usr/lib/os-release
    ln -sf initrd-release $initdir/etc/os-release
}

