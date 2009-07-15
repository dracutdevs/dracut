#!/bin/sh

if $UDEV_QUEUE_EMPTY >/dev/null 2>&1; then
    [ -h "$job" ] && rm -f "$job"
    DM_RAIDS=$(getargs rd_DM_UUID=)
    # run dmraid if udev has settled
    info "Scanning for dmraid devices $DM_RAIDS"
    SETS=$(dmraid -c -s)
    info "Found dmraid sets:"
    echo $SETS|vinfo
    for r in $DM_RAIDS; do 
	for s in $SETS; do 
	    if [ "${s##$r}" != "$s" ]; then
		info "Activating $s"
		dmraid -ay $s | vinfo
	    fi
	done
    done
fi

