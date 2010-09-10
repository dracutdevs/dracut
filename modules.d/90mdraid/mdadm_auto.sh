#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
. /lib/dracut-lib.sh

info "Autoassembling MD Raid"    
/sbin/mdadm -As --auto=yes --run 2>&1 | vinfo
