#!/bin/bash

# called by dracut
check() {
    [[ $mount_needs ]] && return 1

    if ! dracut_module_included "systemd"; then
        derror "systemd-hostnamed needs systemd in the initramfs"
        return 1
    fi

    return 0
}

# called by dracut
depends() {
    echo "systemd systemd-networkd"
}

installkernel() {
    return 0
}

# called by dracut
install() {
    local _mods

    inst_multiple -o \
       $systemdutildir/systemd-hostnamed \
       $systemdsystemunitdir/systemd-hostnamed.service \
       hostname hostnamectl

    if [[ $hostonly ]]; then
       inst_multiple -H -o \
           /etc/hosts \
           /etc/hostname \
    	   /etc/machine-info \
           ${NULL}
    fi

    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libnss_myhostname.so.*"

    systemctl -q --root "$initdir" enable systemd-hostnamed

}
