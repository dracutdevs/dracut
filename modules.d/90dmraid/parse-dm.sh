# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
# nodmraid for anaconda / rc.sysinit compatibility
if getarg rd_NO_DM || getarg nodmraid; then
    info "rd_NO_DM: removing DM RAID activation"
    udevproperty rd_NO_DM=1
fi

if [ ! -x /sbin/mdadm ] || getarg rd_NO_MDIMSM || getarg noiswmd; then
    info "rd_NO_MDIMSM: no MD RAID for imsm/isw raids"
    udevproperty rd_NO_MDIMSM=1
fi

