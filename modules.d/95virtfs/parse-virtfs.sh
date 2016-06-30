#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if [ "${root%%:*}" = "virtfs" ] ; then
    initqueue --onetime modprobe -b -q 9pnet_virtio

    rootok=1
fi
