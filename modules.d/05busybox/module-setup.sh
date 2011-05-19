#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    type -P busybox >/dev/null || return 1

    return 255
}

depends() {
    return 0
}

install() {
    local _i _progs _path
    inst busybox /usr/bin/busybox

    # List of shell programs that we use in other official dracut modules, that
    # must be supported by the busybox installed on the host system
    _progs="echo grep usleep [ rmmod insmod mount uname umount setfont kbd_mode stty gzip bzip2 chvt readlink blkid dd losetup tr sed seq ps more cat rm free ping netstat vi ping6 fsck ip hostname basename mknod mkdir pidof sleep chroot ls cp mv dmesg mkfifo less ln modprobe"

    # FIXME: switch_root should be in the above list, but busybox version hangs
    # (using busybox-1.15.1-7.fc14.i686 at the time of writing)

    for _i in $_progs; do
	_path=$(find_binary "$_i")
        if [[ $_path != ${_path#/usr} ]]; then
    	    ln -s ../../usr/bin/busybox "$initdir/$_path"
        else
            ln -s ../usr/bin/busybox "$initdir/$_path"
        fi
    done

}

