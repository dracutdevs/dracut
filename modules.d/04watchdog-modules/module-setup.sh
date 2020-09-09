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
    return 0
}

installkernel() {
    local -A _drivers
    local _alldrivers _wdtdrv _wdtppath _dir
    [[ -d /sys/class/watchdog/ ]] || return
    for _dir in /sys/class/watchdog/*; do
        [[ -d "$_dir" ]] || continue
        [[ -f "$_dir/state" ]] || continue
        # device/modalias will return driver of this device
        _wdtdrv=$(< "$_dir/device/modalias")
        # There can be more than one module represented by same
        # modalias. Currently load all of them.
        # TODO: Need to find a way to avoid any unwanted module
        # represented by modalias
        _wdtdrv=$(modprobe --set-version "$kernel" -R $_wdtdrv 2>/dev/null)
        if [[ $_wdtdrv ]]; then
            instmods $_wdtdrv
            for i in $_wdtdrv; do
                _drivers[$i]=1
            done
        fi
        # however in some cases, we also need to check that if there is
        # a specific driver for the parent bus/device.  In such cases
        # we also need to enable driver for parent bus/device.
        _wdtppath=$(readlink -f "$_dir/device")
        while [[ -d "$_wdtppath" ]] && [[ "$_wdtppath" != "/sys" ]]; do
            _wdtppath=$(readlink -f "$_wdtppath/..")
            [[ -f "$_wdtppath/modalias" ]] || continue

            _wdtdrv=$(< "$_wdtppath/modalias")
            _wdtdrv=$(modprobe --set-version "$kernel" -R $_wdtdrv 2>/dev/null)
            if [[ $_wdtdrv ]]; then
                instmods $_wdtdrv
                for i in $_wdtdrv; do
                    _drivers[$i]=1
                done
            fi
        done
    done
    # ensure that watchdog module is loaded as early as possible
    _alldrivers="${!_drivers[*]}"
    [[ $_alldrivers ]] && echo "rd.driver.pre=${_alldrivers// /,}" > ${initdir}/etc/cmdline.d/00-watchdog.conf

    return 0
}
