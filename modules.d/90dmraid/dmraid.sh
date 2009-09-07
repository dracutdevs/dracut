#!/bin/sh

. /lib/dracut-lib.sh

DM_RAIDS=$(getargs rd_DM_UUID=)
# run dmraid if udev has settled
info "Scanning for dmraid devices $DM_RAIDS"
if [ -n "$DM_RAIDS" ]; then
    # only activate specified DM RAIDS
    SETS=$(dmraid -c -s)
    info "Found dmraid sets:"
    echo $SETS|vinfo
    for r in $DM_RAIDS; do 
	for s in $SETS; do 
	    if [ "${s##$r}" != "$s" ]; then
		info "Activating $s"
		dmraid -ay $s 2>&1 | vinfo
                udevsettle
	    fi
	done
    done
else 
    # scan and activate all DM RAIDS
    dmraid -ay 2>&1 | vinfo
fi
