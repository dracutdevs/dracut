#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    [[ "$mount_needs" ]] && return 1
    [ -x /sbin/bootchartd ] || return 1
    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_symlink /init /sbin/init
    inst_dir /lib/bootchart/tmpfs

    inst_multiple bootchartd bash \
        /lib/bootchart/bootchart-collector /etc/bootchartd.conf \
        accton \
        echo \
        grep \
        usleep

    inst /usr/bin/pkill /bin/pkill
    inst /usr/bin/[  /bin/[
}

