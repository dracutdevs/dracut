#!/bin/bash

# called by dracut
check() {
    local _arch=${DRACUT_ARCH:-$(uname -m)}
    [ "$_arch" = "s390" -o "$_arch" = "s390x" ] || return 1
    require_binaries dasdconf.sh || return 1
    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_multiple dasdconf.sh
    conf=/etc/dasd.conf
    if [[ $hostonly && -f $conf ]]; then
        inst -H $conf
    fi
    inst_rules 56-dasd.rules
    inst_rules 59-dasd.rules
}
