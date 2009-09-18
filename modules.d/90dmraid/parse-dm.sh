# nodmraid for anaconda / rc.sysinit compatibility
if getarg rd_NO_DM || getarg nodmraid; then
    info "rd_NO_DM: removing DM RAID activation"
    udevproperty rd_NO_DM=1
fi
