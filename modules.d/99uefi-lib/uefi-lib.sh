#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Copyright 2013 Red Hat, Inc.  All rights reserved.
# Copyright 2013 Harald Hoyer <harald@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

getbyte () {
    local IFS= LC_CTYPE=C res c
    read -r -n 1 -d '' c
    res=$?
    # the single quote in the argument of the printf
    # yields the numeric value of $c (ASCII since LC_CTYPE=C)
    [[ -n $c ]] && c=$(printf '%u' "'$c") || c=0
    printf "$c"
    return $res
}

getword () {
    local b1 b2 val
    b1=$(getbyte) || return 1
    b2=$(getbyte) || return 1
    (( val = b2 * 256 + b1 ))
    echo $val
    return 0
}

# Acpi(PNP0A08,0x0)/Pci(0x3,0x0)/Pci(0x0,0x0)/MAC(90E2BA265ED4,0x0)/Vlan(172)/Fibre(0x4EA06104A0CC0050,0x0)
uefi_device_path()
{
    local IFS= LC_CTYPE=C res tt len type hextype first
    first=1

    while :; do
        type=$(getbyte) || return 1
        subtype=$(getbyte) || return 1
        len=$(getword) || return 1
        hextype=$(printf "%02x%02x" "$type" "$subtype")
        if [[ $first == 1 ]]; then
            first=0
        elif [[ $hextype != "7fff" ]]; then
            printf "/"
        fi
        case $hextype in
            0101)
                # PCI
                tt=$(getword)
                printf "PCI(0x%x,0x%x)" $(($tt / 256)) $(($tt & 255))
                ;;
            0201)
                # ACPI
                printf "Acpi(0x%x,0x%x)" $(($(getword) + $(getword) * 65536)) $(($(getword) + $(getword) * 65536))
                ;;
            0303)
                # FIBRE
                getword &>/dev/null
                getword &>/dev/null
                printf "Fibre(0x%x%x%x%x%x%x%x%x,0x%x)" \
                    $(getbyte) $(getbyte) $(getbyte) $(getbyte) \
                    $(getbyte) $(getbyte) $(getbyte) $(getbyte) \
                    $(( $(getword) + $(getword) * 65536 + 4294967296 * ( $(getword) + $(getword) * 65536 ) ))
                ;;
            030b)
                # MAC
                printf "MAC(%02x%02x%02x%02x%02x%02x," $(getbyte) $(getbyte) $(getbyte) $(getbyte) $(getbyte) $(getbyte)
                read -r -N 26  tt || return 1
                printf "0x%x)"  $(getbyte)
                ;;
            0314)
                # VLAN
                printf "VLAN(%d)" $(getword)
                ;;
            7fff)
                # END
                printf "\n"
                return 0
                ;;
            *)
                printf "Unknown(Type:%d SubType:%d len=%d)" "$type" "$subtype" "$len"
                read -r -N $(($len-4))  tt || return 1
                ;;
        esac
    done
}

get_fcoe_boot_mac()
{
    data=${1:-/sys/firmware/efi/vars/FcoeBootDevice-a0ebca23-5f9c-447a-a268-22b6c158c2ac/data}
    [ -f $data ] || return 1
    local IFS= LC_CTYPE=C tt len type hextype
    first=1

    while :; do
        type=$(getbyte) || return 1
        subtype=$(getbyte) || return 1
        len=$(getword) || return 1
        hextype=$(printf "%02x%02x" "$type" "$subtype")
        case $hextype in
            030b)
                # MAC
                printf "%02x:%02x:%02x:%02x:%02x:%02x" $(getbyte) $(getbyte) $(getbyte) $(getbyte) $(getbyte) $(getbyte)
                read -r -N 27  tt || return 1
                ;;
            7fff)
                # END
                return 0
                ;;
            *)
                read -r -N $(($len-4))  tt || return 1
                ;;
        esac
    done < $data
}

get_fcoe_boot_vlan()
{
    data=${1:-/sys/firmware/efi/vars/FcoeBootDevice-a0ebca23-5f9c-447a-a268-22b6c158c2ac/data}
    [ -f $data ] || return 1
    local IFS= LC_CTYPE=C tt len type hextype
    first=1

    while :; do
        type=$(getbyte) || return 1
        subtype=$(getbyte) || return 1
        len=$(getword) || return 1
        hextype=$(printf "%02x%02x" "$type" "$subtype")
        case $hextype in
            0314)
                # VLAN
                printf "%d" $(getword)
                ;;
            7fff)
                # END
                return 0
                ;;
            *)
                read -r -N $(($len-4))  tt || return 1
                ;;
        esac
    done < $data
}
