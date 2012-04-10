#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    return 255
}

depends() {
    return 0
}

installkernel() {
    local _fipsmodules _mod
    _fipsmodules="aead aes_generic aes-xts aes-x86_64 ansi_cprng cbc ccm chainiv ctr"
    _fipsmodules+=" des deflate ecb eseqiv hmac seqiv sha256 sha512"
    _fipsmodules+=" cryptomgr crypto_null tcrypt dm-mod dm-crypt"

    mkdir -m 0755 -p "${initdir}/etc/modprobe.d"

    for _mod in $_fipsmodules; do
        if instmods $_mod; then
            echo $_mod >> "${initdir}/etc/fipsmodules"
            echo "blacklist $_mod" >> "${initdir}/etc/modprobe.d/fips.conf"
        fi
    done
}

install() {
    local _dir
    inst_hook pre-trigger 01 "$moddir/fips-boot.sh"
    inst_hook pre-pivot 01 "$moddir/fips-noboot.sh"
    inst "$moddir/fips.sh" /sbin/fips.sh

    dracut_install sha512hmac rmmod insmod mount uname umount

    inst_libdir_file libsoftokn3.so
    inst_libdir_file libsoftokn3.so
    inst_libdir_file libsoftokn3.chk
    inst_libdir_file libfreebl3.so
    inst_libdir_file libfreebl3.chk

    dracut_install $usrlibdir/hmaccalc/sha512hmac.hmac
    if command -v prelink >/dev/null; then
        dracut_install prelink
    fi
}

