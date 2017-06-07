#!/usr/bin/env bash

# called by dracut
check() {
    local _arch=$(uname -m)
    [ "$_arch" = "s390" -o "$_arch" = "s390x" ] || return 1
    require_binaries zfcp_disk_configure /usr/lib/udev/collect || return 1
    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_multiple /usr/lib/udev/collect
    inst_hook cmdline 30 "$moddir/parse-zfcp.sh"
    if [[ $hostonly ]] ; then
        inst_rules_wildcard 51-zfcp-*.rules
    fi
}
