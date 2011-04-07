#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
# nodmraid for anaconda / rc.sysinit compatibility
if ! getargbool 1 rd.dm -n rd_NO_DM || getarg nodmraid; then
    info "rd.dm=0: removing DM RAID activation"
    udevproperty rd_NO_DM=1
fi

if  ! command -v mdadm >/dev/null || ! getargbool 1 rd.md.imsm -n rd_NO_MDIMSM || getarg noiswmd; then
    info "rd.md.imsm=0: no MD RAID for imsm/isw raids"
    udevproperty rd_NO_MDIMSM=1
fi

