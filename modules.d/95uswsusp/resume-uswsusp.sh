#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

case "$splash" in
    quiet )
        a_splash="-P splash=y"
        ;;
    * )
        a_splash="-P splash=n"
        ;;
esac

if [ -n "$resume" ]; then
    /usr/sbin/resume $a_splash "$resume"
fi
