#!/bin/sh

if dcssblk_arg=$(getarg rd.dcssblk=); then
    info "Loading dcssblk segments=$dcssblk_arg"
    modprobe dcssblk segments="$dcssblk_arg"
fi
