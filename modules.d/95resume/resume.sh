#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

[ -s /.resume -a -b "$resume" ] && {
    # parsing the output of ls is Bad, but until there is a better way...
    ls -lH "$resume" | ( 
        read x x x x maj min x;
        echo "${maj%,}:$min"> /sys/power/resume)
    >/.resume
}
