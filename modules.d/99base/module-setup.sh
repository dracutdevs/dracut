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
    mkdir -p ${initdir}/initqueue
    mkdir -p ${initdir}/emergency
    mkdir -p ${initdir}/initqueue-finished
    mkdir -p ${initdir}/initqueue-settled
    mkdir -p ${initdir}/tmp
    # Bail out if switch_root does not exist
    if type -P switch_root >/dev/null; then
        inst $(type -P switch_root) /sbin/switch_root \
            || derror "Failed to install switch_root"
    else
        inst "$moddir/switch_root" "/sbin/switch_root" \
            || derror "Failed to install switch_root"
    fi
    inst "$moddir/dracut-lib.sh" "/lib/dracut-lib.sh"
    inst_hook cmdline 10 "$moddir/parse-root-opts.sh"
    inst_hook cmdline 20 "$moddir/parse-blacklist.sh"
    mkdir -p "${initdir}/var"
    [ -x /lib/systemd/systemd-timestamp ] && inst /lib/systemd/systemd-timestamp
}

