#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

[ -z "${DRACUT_SYSTEMD}" ] && [ -e /sys/module/bnx2i ] && killproc iscsiuio

