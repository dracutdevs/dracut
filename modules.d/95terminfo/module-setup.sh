#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

install() {
    local _terminfodir
    # terminfo bits make things work better if you fall into interactive mode
    for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
        [ -f ${_terminfodir}/l/linux ] && break
    done

    if [ -d ${_terminfodir} ]; then
        for i in "l/linux" "v/vt100" "v/vt102" "v/vt220"; do
            inst_dir "$_terminfodir/${i%/*}"
            cp --reflink=auto --sparse=auto -prfL -t "${initdir}/${_terminfodir}/${i%/*}" "$_terminfodir/$i"
        done
    fi
}
