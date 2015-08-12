#!/bin/sh

[ -z "${DRACUT_SYSTEMD}" ] && [ -e /sys/module/bnx2i ] && killproc iscsiuio

