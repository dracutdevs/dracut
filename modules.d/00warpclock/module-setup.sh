#!/usr/bin/bash

# called by dracut
check() {
    # hwclock does not exist on S390(x), bail out silently then
    local _arch=${DRACUT_ARCH:-$(uname -m)}
    [ "$_arch" = "s390" -o "$_arch" = "s390x" ] && return 1

    [ -e /etc/localtime -a -e /etc/adjtime ] || return 1
    require_binaries /usr/sbin/hwclock || return 1

    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst /usr/share/zoneinfo/UTC
    inst /etc/localtime
    inst /etc/adjtime
    inst_hook pre-trigger 00 "$moddir/warpclock.sh"
    inst /usr/sbin/hwclock
}
