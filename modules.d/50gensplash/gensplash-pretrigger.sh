#!/bin/sh

if ! getarg rd_NO_SPLASH; then
    [ -c /dev/null ] || mknod /dev/null c 1 3
    [ -c /dev/console ] || mknod /dev/console c 5 1
    [ -c /dev/tty0 ] || mknod /dev/tty0 c 4 0

    info "Starting Gentoo Splash"

    /lib/udev/console_init tty0
    CDROOT=0
    . /lib/gensplash-lib.sh
    splash init
fi
