#!/bin/sh

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
    local _drivers _wdtdrv

    _drivers=
    for _wd in /sys/class/watchdog/*; do
        [ -e "$_wd" ] || continue
        _wdtdrv=$(get_dev_module "$_wd")
        if [ -n "$_wdtdrv" ]; then
            _drivers="$_drivers $_wdtdrv"
        fi
    done
    # shellcheck disable=SC2086
    instmods $_drivers

    # ensure that watchdog module is loaded as early as possible
    # shellcheck disable=SC2086,SC2116
    [ -n "${_drivers}" ] && echo "rd.driver.pre=\"$(echo $_drivers)\"" > "${initdir}"/etc/cmdline.d/00-watchdog.conf
    return 0
}
