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
    local _d
    dracut_install mount mknod mkdir modprobe pidof sleep chroot \
        sed ls flock cp mv dmesg rm ln rmmod mkfifo umount readlink
    dracut_install -o less
    [[ $cttyhack = yes ]] && dracut_install -o setsid
    if [ ! -e "${initdir}/bin/sh" ]; then
        dracut_install bash
        (ln -s bash "${initdir}/bin/sh" || :)
    fi

    #add common users in /etc/passwd, it will be used by nfs/ssh currently
    egrep '^root:' "$initdir/etc/passwd" 2>/dev/null || echo  'root:x:0:0::/root:/bin/sh' >> "$initdir/etc/passwd"
    egrep '^nobody:' /etc/passwd >> "$initdir/etc/passwd"
    # install our scripts and hooks
    inst "$moddir/init.sh" "/init"
    inst "$moddir/initqueue.sh" "/sbin/initqueue"
    inst "$moddir/loginit.sh" "/sbin/loginit"

    [ -e "${initdir}/lib" ] || mkdir -m 0755 -p ${initdir}/lib
    mkdir -m 0755 -p ${initdir}/lib/dracut
    mkdir -m 0755 -p ${initdir}/lib/dracut/hooks

    mkdir -p ${initdir}/tmp

    dracut_install switch_root || dfatal "Failed to install switch_root"

    inst "$moddir/dracut-lib.sh" "/lib/dracut-lib.sh"
    inst "$moddir/mount-hook.sh" "/usr/bin/mount-hook"
    inst_hook cmdline 10 "$moddir/parse-root-opts.sh"
    mkdir -p "${initdir}/var"
    [ -x /lib/systemd/systemd-timestamp ] && inst /lib/systemd/systemd-timestamp
    if [[ $realinitpath ]]; then
        for i in $realinitpath; do 
            echo "rd.distroinit=$i"
        done > "${initdir}/etc/cmdline.d/distroinit.conf"
    fi

}

