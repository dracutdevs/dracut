#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if resume=$(getarg resume=) && ! getarg noresume; then
    export resume
    echo "$resume" >/.resume
else
    unset resume
fi

case "$resume" in
    LABEL=*) \
        resume="$(echo $resume | sed 's,/,\\x2f,g')"
        resume="/dev/disk/by-label/${resume#LABEL=}" ;;
    UUID=*) \
        resume="/dev/disk/by-uuid/${resume#UUID=}" ;;
    PARTUUID=*) \
        resume="/dev/disk/by-partuuid/${resume#PARTUUID=}" ;;
esac

if splash=$(getarg splash=); then
    export splash
else
    unset splash
fi
