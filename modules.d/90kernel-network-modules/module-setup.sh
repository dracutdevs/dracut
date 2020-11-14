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
installkernel() {
    # Include wired net drivers, excluding wireless
    local _arch=${DRACUT_ARCH:-$(uname -m)}
    local _net_symbols='eth_type_trans|register_virtio_device|usbnet_open'
    local _unwanted_drivers='/(wireless|isdn|uwb|net/ethernet|net/phy|net/team)/'
    local _net_drivers

    if [ "$_arch" = "s390" -o "$_arch" = "s390x" ]; then
        dracut_instmods -o -P ".*${_unwanted_drivers}.*" -s "$_net_symbols" "=drivers/s390/net"
    fi

    if [[ $hostonly_mode == 'strict' ]] && [[ $hostonly_nics ]]; then
        for _nic in $hostonly_nics; do
            _net_drivers=$(get_dev_module /sys/class/net/$_nic)
            if ! [[ $_net_drivers ]]; then
                derror "--hostonly-nics contains invalid NIC '$_nic'"
                continue
            fi
            hostonly="" instmods $_net_drivers
        done
        return 0
    fi

    dracut_instmods -o -P ".*${_unwanted_drivers}.*" -s "$_net_symbols" "=drivers/net"
    #instmods() will take care of hostonly
    instmods \
        =drivers/net/phy \
        =drivers/net/team \
        =drivers/net/ethernet \
        ecb arc4 bridge stp llc ipv6 bonding 8021q ipvlan macvlan af_packet virtio_net xennet
}

# called by dracut
install() {
    return 0
}

