#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    return 0
}

depends() {
    echo udev-rules 
    return 0
}

install() {
    dracut_install mount mknod mkdir modprobe pidof sleep chroot \
        sed ls flock cp mv dmesg rm ln rmmod mkfifo 
    dracut_install -o less 
    if [ ! -e "${initdir}/bin/sh" ]; then
        dracut_install bash
        (ln -s bash "${initdir}/bin/sh" || :)
    fi
    # install our scripts and hooks
    inst "$moddir/init" "/init"
    inst "$moddir/initqueue" "/sbin/initqueue"
    inst "$moddir/loginit" "/sbin/loginit"

    mkdir -m 0755 -p ${initdir}/lib
    mkdir -m 0755 -p ${initdir}/lib/dracut
    mkdir -m 0755 -p ${initdir}/lib/dracut/hooks
    for d in $hookdirs emergency \
        initqueue initqueue/finished initqueue/settled; do
        mkdir -m 0755 -p ${initdir}/lib/dracut/hooks/$d
    done

    mkdir -p ${initdir}/tmp

    dracut_install switch_root || dfatal "Failed to install switch_root"

    inst "$moddir/dracut-lib.sh" "/lib/dracut-lib.sh"
    inst_hook cmdline 10 "$moddir/parse-root-opts.sh"
    mkdir -p "${initdir}/var"
    [ -x /lib/systemd/systemd-timestamp ] && inst /lib/systemd/systemd-timestamp
}

