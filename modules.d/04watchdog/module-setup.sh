#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    # Do not add watchdog hooks if systemd module is included
    # In that case, systemd will manage watchdog kick
    if dracut_module_included "systemd"; then
	    return
    fi
    inst_hook cmdline   00 "$moddir/watchdog.sh"
    inst_hook cmdline   50 "$moddir/watchdog.sh"
    inst_hook pre-trigger 00 "$moddir/watchdog.sh"
    inst_hook initqueue 00 "$moddir/watchdog.sh"
    inst_hook mount     00 "$moddir/watchdog.sh"
    inst_hook mount     50 "$moddir/watchdog.sh"
    inst_hook mount     99 "$moddir/watchdog.sh"
    inst_hook pre-pivot 00 "$moddir/watchdog.sh"
    inst_hook pre-pivot 99 "$moddir/watchdog.sh"
    inst_hook cleanup   00 "$moddir/watchdog.sh"
    inst_hook cleanup   99 "$moddir/watchdog.sh"
    inst_hook emergency 02 "$moddir/watchdog-stop.sh"
    inst_multiple -o wdctl
}

installkernel() {
    [[ -d /sys/class/watchdog/ ]] || return
    for dir in /sys/class/watchdog/*; do
	    [[ -d "$dir" ]] || continue
	    [[ -f "$dir/state" ]] || continue
	    active=$(< "$dir/state")
	    ! [[ $hostonly ]] || [[ "$active" =  "active" ]] || continue
	    # device/modalias will return driver of this device
	    wdtdrv=$(< "$dir/device/modalias")
	    # There can be more than one module represented by same
	    # modalias. Currently load all of them.
	    # TODO: Need to find a way to avoid any unwanted module
	    # represented by modalias
	    wdtdrv=$(modprobe -R $wdtdrv)
	    instmods $wdtdrv
	    # however in some cases, we also need to check that if there is
	    # a specific driver for the parent bus/device.  In such cases
	    # we also need to enable driver for parent bus/device.
	    wdtppath=$(readlink -f "$dir/device/..")
	    while [ -f "$wdtppath/modalias" ]
	    do
		    wdtpdrv=$(< "$wdtppath/modalias")
		    wdtpdrv=$(modprobe -R $wdtpdrv)
		    instmods $wdtpdrv
		    wdtppath=$(readlink -f "$wdtppath/..")
	    done
    done
}
