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
    FIPSMODULES="aead aes_generic aes-x86_64 ansi_cprng cbc ccm chainiv ctr"
    FIPSMODULES="$FIPSMODULES des deflate ecb eseqiv hmac seqiv sha256 sha512"
    FIPSMODULES="$FIPSMODULES cryptomgr crypto_null tcrypt" 

    mkdir -p "${initdir}/etc/modprobe.d"

    for mod in $FIPSMODULES; do 
        if instmods $mod; then
            echo $mod >> "${initdir}/etc/fipsmodules"
            echo "blacklist $mod" >> "${initdir}/etc/modprobe.d/fips.conf"
        fi
    done
}

install() {
    inst_hook pre-trigger 01 "$moddir/fips.sh"
    dracut_install sha512hmac rmmod insmod mount uname umount

    for dir in "$usrlibdir" "$libdir"; do
        [[ -e $dir/libsoftokn3.so ]] && \
            dracut_install $dir/libsoftokn3.so $dir/libsoftokn3.chk \
            $dir/libfreebl3.so $dir/libfreebl3.chk && \
            break
    done

    dracut_install $usrlibdir/hmaccalc/sha512hmac.hmac
}

