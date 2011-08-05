#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
strstr "$(cat /proc/misc)" device-mapper || modprobe dm_mod
modprobe dm_mirror 2>/dev/null
