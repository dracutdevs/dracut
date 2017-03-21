#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    return 0
}

running_in_qemu() {
    if type -P systemd-detect-virt >/dev/null 2>&1; then
        vm=$(systemd-detect-virt --vm 2>&1)
        (($? != 0)) && return 255
        [[ $vm = "qemu" ]] && return 0
        [[ $vm = "kvm" ]] && return 0
        [[ $vm = "bochs" ]] && return 0
    fi

    for i in /sys/class/dmi/id/*_vendor; do
        [[ -f $i ]] || continue
        read vendor < $i
        [[  "$vendor" == "QEMU" ]] && return 0
        [[  "$vendor" == "Bochs" ]] && return 0
    done

    return 255
}

# called by dracut
installkernel() {
    # Include wired net drivers, excluding wireless
    local _arch=$(uname -m)
    local _net_drivers='eth_type_trans|register_virtio_device|usbnet_open'
    local _unwanted_drivers='/(wireless|isdn|uwb|net/ethernet|net/phy|net/team)/'

    if [ "$_arch" = "s390" -o "$_arch" = "s390x" ]; then
        _s390drivers="=drivers/s390/net"
    fi

    dracut_instmods -o -P ".*${_unwanted_drivers}.*" -s "$_net_drivers" "=drivers/net" ${_s390drivers:+"$_s390drivers"}

    #instmods() will take care of hostonly
    instmods \
        =drivers/net/phy \
        =drivers/net/team \
        =drivers/net/ethernet \
        ecb arc4 bridge stp llc ipv6 bonding 8021q af_packet virtio_net xennet
    hostonly="" instmods iscsi_ibft crc32c iscsi_boot_sysfs

    if running_in_qemu; then
        hostonly='' instmods virtio_net e1000 8139cp pcnet32 e100 ne2k_pci
    else
        return 0
    fi
}

# called by dracut
install() {
    return 0
}

