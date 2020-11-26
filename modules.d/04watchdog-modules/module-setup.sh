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

    for _wd in /sys/class/watchdog/*; do
        ! [ -e $_wd ] && continue
        _wdtdrv=$(get_dev_module $_wd)
        if [[ $_wdtdrv ]]; then
            instmods $_wdtdrv
            for i in $_wdtdrv; do
                _drivers[$i]=1
            done
        fi
    done

    # ensure that watchdog module is loaded as early as possible
    _alldrivers="${!_drivers[*]}"
    [[ $_alldrivers ]] && echo "rd.driver.pre=${_alldrivers// /,}" > ${initdir}/etc/cmdline.d/00-watchdog.conf

    return 0
}
