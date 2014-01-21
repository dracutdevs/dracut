#!/bin/bash

# called by dracut
cmdline() {
    is_zfcp() {
        local _dev=$1
        local _devpath=$(cd -P /sys/dev/block/$_dev ; echo $PWD)
        local _sdev _lun _wwpn _ccw

        [ "${_devpath#*/sd}" == "$_devpath" ] && return 1
        _sdev="${_devpath%%/block/*}"
        [ -e ${_sdev}/fcp_lun ] || return 1
        _lun=$(cat ${_sdev}/fcp_lun)
        _wwpn=$(cat ${_sdev}/wwpn)
        _ccw=$(cat ${_sdev}/hba_id)
        echo "rd.zfcp=${_ccw},${_wwpn},${_lun}"
        return 1
    }
    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for_each_host_dev_and_slaves is_zfcp
    }
}

# called by dracut
check() {
    local _arch=$(uname -m)
    local _ccw
    [ "$_arch" = "s390" -o "$_arch" = "s390x" ] || return 1
    require_binaries /usr/lib/udev/collect || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for _ccw in /sys/bus/ccw/devices/*/host* ; do
            [ -d "$_ccw" ] || continue
            found=$(($found+1));
        done
        [ $found -eq 0 ] && return 255
    }
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
    if [[ $hostonly_cmdline == "yes" ]] ; then
        local _zfcp

        for _zfcp in $(cmdline) ; do
            printf "%s\n" "$zfcp" >> "${initdir}/etc/cmdline.d/94zfcp.conf"
        done
    fi
    if [[ $hostonly ]] ; then
        inst_rules_wildcard 51-zfcp-*.rules
        inst_rules_wildcard 41-s390x-zfcp-*.rules
    fi
}
