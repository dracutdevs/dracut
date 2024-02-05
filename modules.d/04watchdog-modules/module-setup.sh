#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    return 0
}

get_watchdog_drivers() {
    local _wd _wdtdrv

    for _wd in /sys/class/watchdog/*; do
        ! [ -e "$_wd" ] && continue
        _wdtdrv=$(get_dev_module "$_wd")
        if [[ $_wdtdrv ]]; then
            echo "$_wdtdrv"
        fi
    done
}

# called by dracut
cmdline() {
    local -a _drivers
    local _drivers_joined

    if [[ $# -gt 0 ]]; then
        printf -v _drivers_joined '%s,' "$@"
    else
        mapfile -t _drivers < <(get_watchdog_drivers)
        if ((${#_drivers[@]})); then
            printf -v _drivers_joined '%s,' "${_drivers[@]}"
        fi
    fi
    [[ $_drivers_joined ]] && printf ' rd.driver.pre="%s"' "${_drivers_joined%,}"
}

# called by dracut
installkernel() {
    local -a _drivers
    local _wdconf

    mapfile -t _drivers < <(get_watchdog_drivers)
    if ((${#_drivers[@]})); then
        instmods "${_drivers[@]}"
        # shellcheck disable=SC2068
        _wdconf=$(cmdline ${_drivers[@]})
        if [[ $_wdconf ]]; then
            printf "%s\n" "$_wdconf" > "${initdir}/etc/cmdline.d/00-watchdog.conf"
        fi
    fi

    return 0
}
