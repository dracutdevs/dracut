#!/bin/bash

# called by dracut
check() {
    [[ $mount_needs ]] && return 1

    if ! dracut_module_included "systemd"; then
        derror "systemd-resolved needs systemd in the initramfs"
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
       $systemdutildir/systemd-resolved \
       $systemdsystemunitdir/systemd-resolved.service \

    if [[ $hostonly ]]; then
       inst_multiple -H -o \
           /etc/systemd/resolved.conf \
           /etc/systemd/resolved.conf.d/*.conf \
           ${NULL}
   fi

   grep '^systemd-resolve:' $dracutsysrootdir/etc/passwd 2>/dev/null >> "$initdir/etc/passwd"
   grep '^systemd-resolve:' $dracutsysrootdir/etc/group >> "$initdir/etc/group"

   _arch=${DRACUT_ARCH:-$(uname -m)}
   inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libnss_resolve.so.*"

   systemctl -q --root "$initdir" enable systemd-resolved.service
}
