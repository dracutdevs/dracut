#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

install() {
    # terminfo bits make things work better if you fall into interactive mode
    for TERMINFODIR in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
        [ -d ${TERMINFODIR} ] && break
    done
    
    [ -d ${TERMINFODIR} ] && \
        dracut_install $(find ${TERMINFODIR} -type f)
}

