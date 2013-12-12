#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

command -v getarg >/dev/null          || . /lib/dracut-lib.sh
command -v get_fcoe_boot_mac >/dev/null || . /lib/uefi-lib.sh
command -v set_ifname >/dev/null || . /lib/net-lib.sh

print_fcoe_uefi_conf()
{
    local mac dev vlan
    mac=$(get_fcoe_boot_mac)
    [ -z "$mac" ] && continue
    dev=$(set_ifname fcoe $mac)
    vlan=$(get_fcoe_boot_vlan)
    if [ "$vlan" -ne "0" ]; then
        case "$vlan" in
            [0-9]*)
                printf "%s\n" "vlan=$dev.$vlan:$dev"
                dev="$dev.$vlan"
                ;;
            *)
                printf "%s\n" "vlan=$vlan:$dev"
                dev="$vlan"
                ;;
        esac
    fi
    # fcoe=eth0:nodcb
    printf "%s\n" "$dev:nodcb"
}


if [ -e /sys/firmware/efi/vars/FcoeBootDevice-a0ebca23-5f9c-447a-a268-22b6c158c2ac/data ]; then
    print_fcoe_uefi_conf > /etc/cmdline.d/40-fcoe-uefi.conf
fi
