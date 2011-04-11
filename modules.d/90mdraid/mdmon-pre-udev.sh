#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
# save state dir for mdmon/mdadm for the real root
[ -d /run/mdadm ] || mkdir -m 0755 /run/mdadm
# backward compat link
