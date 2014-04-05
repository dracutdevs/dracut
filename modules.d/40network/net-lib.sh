#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

get_ip() {
    local iface="$1" ip=""
    ip=$(ip -o -f inet addr show $iface)
    ip=${ip%%/*}
    ip=${ip##* }
}

iface_for_remote_addr() {
    set -- $(ip -o route get to $1)
    echo $5
}

iface_for_ip() {
    set -- $(ip -o addr show to $1)
    echo $2
}

iface_for_mac() {
    local interface="" mac="$(echo $1 | sed 'y/ABCDEF/abcdef/')"
    for interface in /sys/class/net/*; do
        if [ $(cat $interface/address) = "$mac" ]; then
            echo ${interface##*/}
        fi
    done
}

# get the iface name for the given identifier - either a MAC, IP, or iface name
iface_name() {
    case $1 in
        ??:??:??:??:??:??|??-??-??-??-??-??) iface_for_mac $1 ;;
        *:*:*|*.*.*.*) iface_for_ip $1 ;;
        *) echo $1 ;;
    esac
}

# list the configured interfaces
configured_ifaces() {
    local IFACES="" iface_id="" rv=1
    [ -e "/tmp/net.ifaces" ] && read IFACES < /tmp/net.ifaces
    if { pidof udevd || pidof systemd-udevd; } > /dev/null; then
        for iface_id in $IFACES; do
            echo $(iface_name $iface_id)
            rv=0
        done
    else
        warn "configured_ifaces called before udev is running"
        echo $IFACES
        [ -n "$IFACES" ] && rv=0
    fi
    return $rv
}

all_ifaces_up() {
    local iface="" IFACES=""
    [ -e "/tmp/net.ifaces" ] && read IFACES < /tmp/net.ifaces
    for iface in $IFACES; do
        [ -e /tmp/net.$iface.up ] || return 1
    done
}

get_netroot_ip() {
    local prefix="" server="" rest=""
    splitsep "$1" ":" prefix server rest
    case $server in
        [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*) echo "$server"; return 0 ;;
    esac
    return 1
}

ip_is_local() {
    strstr "$(ip route get $1 2>/dev/null)" " via "
}

ifdown() {
    local netif="$1"
    # ip down/flush ensures that routing info goes away as well
    ip link set $netif down
    ip addr flush dev $netif
    echo "#empty" > /etc/resolv.conf
    rm -f -- /tmp/net.$netif.did-setup
    [ -e /sys/class/net/$netif/address ] && \
        rm -f -- /tmp/net.$(cat /sys/class/net/$netif/address).did-setup
    # TODO: send "offline" uevent?
}

setup_net() {
    local netif="$1" f="" gw_ip="" netroot_ip="" iface="" IFACES=""
    [ -e /tmp/net.$netif.did-setup ] && return
    [ -e /sys/class/net/$netif/address ] && \
        [ -e /tmp/net.$(cat /sys/class/net/$netif/address).did-setup ] && return
    [ -e "/tmp/net.ifaces" ] && read IFACES < /tmp/net.ifaces
    [ -z "$IFACES" ] && IFACES="$netif"
    # run the scripts written by ifup
    [ -e /tmp/net.$netif.gw ]            && . /tmp/net.$netif.gw
    [ -e /tmp/net.$netif.hostname ]      && . /tmp/net.$netif.hostname
    [ -e /tmp/net.$netif.override ]      && . /tmp/net.$netif.override
    [ -e /tmp/dhclient.$netif.dhcpopts ] && . /tmp/dhclient.$netif.dhcpopts
    # set up resolv.conf
    [ -e /tmp/net.$netif.resolv.conf ] && \
        cp -f /tmp/net.$netif.resolv.conf /etc/resolv.conf

    # Handle STP Timeout: arping the default gateway.
    # (or the root server, if a) it's local or b) there's no gateway.)
    # Note: This assumes that if no router is present the
    # root server is on the same subnet.

    # Get DHCP-provided router IP, or the cmdline-provided "gw=" argument
    [ -n "$new_routers" ] && gw_ip=${new_routers%%,*}
    [ -n "$gw" ] && gw_ip=$gw

    # Get the "netroot" IP (if there's an IP address in there)
    netroot_ip=$(get_netroot_ip $netroot)

    # try netroot if it's local (or there's no gateway)
    if ip_is_local $netroot_ip || [ -z "$gw_ip" ]; then
        dest="$netroot_ip"
    else
        dest="$gw_ip"
    fi

    unset layer2
    if [ -f /sys/class/net/$netif/device/layer2 ]; then
        read layer2 < /sys/class/net/$netif/device/layer2
    fi

    if [ "$layer2" != "0" ] && [ -n "$dest" ] && ! strstr "$dest" ":"; then
        arping -q -f -w 60 -I $netif $dest || info "Resolving $dest via ARP on $netif failed"
    fi
    unset layer2

    > /tmp/net.$netif.did-setup
    [ -e /sys/class/net/$netif/address ] && \
        > /tmp/net.$(cat /sys/class/net/$netif/address).did-setup
}

save_netinfo() {
    local netif="$1" IFACES="" f="" i=""
    [ -e /tmp/net.ifaces ] && read IFACES < /tmp/net.ifaces
    # Add $netif to the front of IFACES (if it's not there already).
    set -- "$netif"
    for i in $IFACES; do [ "$i" != "$netif" ] && set -- "$@" "$i"; done
    IFACES="$*"
    for i in $IFACES; do
        for f in /tmp/dhclient.$i.*; do
            [ -f $f ] && cp -f $f /tmp/net.${f#/tmp/dhclient.}
        done
    done
    echo $IFACES > /tmp/.net.ifaces.new
    mv /tmp/.net.ifaces.new /tmp/net.ifaces
}

set_ifname() {
    local name="$1" mac="$2" num=-1 n=""
    # if it's already set, return the existing name
    for n in $(getargs ifname=); do
        strstr "$n" "$mac" && echo ${n%%:*} && return
    done
    # otherwise, pick a new name and use that
    while :; do
        num=$(($num+1));
        [ -e /sys/class/net/$name$num ] && continue
        for n in $(getargs ifname=); do
            [ "$name$num" = "${n%%:*}" ] && continue 2
        done
        break
    done
    echo "ifname=$name$num:$mac" >> /etc/cmdline.d/45-ifname.conf
    echo "$name$num"
}

# pxelinux provides macaddr '-' separated, but we need ':'
fix_bootif() {
    local macaddr=${1}
    local IFS='-'
    macaddr=$(for i in ${macaddr} ; do echo -n $i:; done)
    macaddr=${macaddr%:}
    # strip hardware type field from pxelinux
    [ -n "${macaddr%??:??:??:??:??:??}" ] && macaddr=${macaddr#??:}
    # return macaddr with lowercase alpha characters expected by udev
    echo $macaddr | sed 'y/ABCDEF/abcdef/'
}

ibft_to_cmdline() {
    local iface=""
    modprobe -q iscsi_ibft
    (
        for iface in /sys/firmware/ibft/ethernet*; do
            local mac="" dev=""
            local dhcp="" ip="" gw="" mask="" hostname=""
            local dns1 dns2

            [ -e ${iface}/mac ] || continue
            mac=$(read a < ${iface}/mac; echo $a)
            [ -z "$mac" ] && continue
            dev=$(set_ifname ibft $mac)

            [ -e /tmp/net.${dev}.has_ibft_config ] && continue

            [ -e ${iface}/dhcp ] && dhcp=$(read a < ${iface}/dhcp; echo $a)

            if [ -n "$dhcp" ]; then
                echo "ip=$dev:dhcp"
            elif [ -e ${iface}/ip-addr ]; then
                [ -e ${iface}/ip-addr ] && ip=$(read a < ${iface}/ip-addr; echo $a)
                # skip not assigned ip adresses
                [ "$ip" = "0.0.0.0" ] && continue
                [ -e ${iface}/gateway ] && gw=$(read a < ${iface}/gateway; echo $a)
                [ -e ${iface}/subnet-mask ] && mask=$(read a < ${iface}/subnet-mask; echo $a)
                [ -e ${iface}/primary-dns ] && dns1=$(read a < ${iface}/primary-dns; echo $a)
                [ -e ${iface}/secondary-dns ] && dns2=$(read a < ${iface}/secondary-dns; echo $a)
                [ -e ${iface}/hostname ] && hostname=$(read a < ${iface}/hostname; echo $a)
                if [ -n "$ip" ] && [ -n "$mask" ]; then
                    echo "ip=$ip::$gw:$mask:$hostname:$dev:none${dns1:+:$dns1}${dns2:+:$dns2}"
                else
                    warn "${iface} does not contain a valid iBFT configuration"
                    warn "ip-addr=$ip"
                    warn "gateway=$gw"
                    warn "subnet-mask=$mask"
                    warn "hostname=$hostname"
                fi
            else
                info "${iface} does not contain a valid iBFT configuration"
                ls -l ${iface} | vinfo
            fi

            if [ -e ${iface}/vlan ]; then
               vlan=$(read a < ${iface}/vlan; echo $a)
               if [ "$vlan" -ne "0" ]; then
                   case "$vlan" in
                       [0-9]*)
                           echo "vlan=$dev.$vlan:$dev"
                           ;;
                       *)
                           echo "vlan=$vlan:$dev"
                           ;;
                   esac
               fi
            fi

            echo $mac > /tmp/net.${dev}.has_ibft_config
        done
    ) >> /etc/cmdline.d/40-ibft.conf
}

parse_iscsi_root()
{
    local v
    v=${1#iscsi:}

# extract authentication info
    case "$v" in
	*@*:*:*:*:*)
	    authinfo=${v%%@*}
	    v=${v#*@}
    # allow empty authinfo to allow having an @ in iscsi_target_name like this:
    # netroot=iscsi:@192.168.1.100::3260::iqn.2009-01.com.example:testdi@sk
	    if [ -n "$authinfo" ]; then
		OLDIFS="$IFS"
		IFS=:
		set $authinfo
		IFS="$OLDIFS"
		if [ $# -gt 4 ]; then
		    warn "Wrong authentication info in iscsi: parameter!"
		    return 1
		fi
		iscsi_username=$1
		iscsi_password=$2
		if [ $# -gt 2 ]; then
		    iscsi_in_username=$3
		    iscsi_in_password=$4
		fi
	    fi
	    ;;
    esac

# extract target ip
    case "$v" in
	[[]*[]]:*)
	    iscsi_target_ip=${v#[[]}
		iscsi_target_ip=${iscsi_target_ip%%[]]*}
	    v=${v#[[]$iscsi_target_ip[]]:}
	    ;;
	*)
	    iscsi_target_ip=${v%%[:]*}
	    v=${v#$iscsi_target_ip:}
	    ;;
    esac

# extract target name
    case "$v" in
	*:iqn.*)
	    iscsi_target_name=iqn.${v##*:iqn.}
	    v=${v%:iqn.*}:
	    ;;
	*:eui.*)
	    iscsi_target_name=iqn.${v##*:eui.}
	    v=${v%:iqn.*}:
	    ;;
	*:naa.*)
	    iscsi_target_name=iqn.${v##*:naa.}
	    v=${v%:iqn.*}:
	    ;;
	*)
	    warn "Invalid iscii target name, should begin with 'iqn.' or 'eui.' or 'naa.'"
	    return 1
	    ;;
    esac

# parse the rest
    OLDIFS="$IFS"
    IFS=:
    set $v
    IFS="$OLDIFS"

    iscsi_protocol=$1; shift # ignored
    iscsi_target_port=$1; shift
    if [ $# -eq 3 ]; then
	iscsi_iface_name=$1; shift
    fi
    if [ $# -eq 2 ]; then
	iscsi_netdev_name=$1; shift
    fi
    iscsi_lun=$1; shift
    if [ $# -ne 0 ]; then
	warn "Invalid parameter in iscsi: parameter!"
	return 1
    fi
}

ip_to_var() {
    local v=${1}:
    local i
    set --
    while [ -n "$v" ]; do
        if [ "${v#\[*:*:*\]:}" != "$v" ]; then
            # handle IPv6 address
            i="${v%%\]:*}"
            i="${i##\[}"
            set -- "$@" "$i"
            v=${v#\[$i\]:}
        else
            set -- "$@" "${v%%:*}"
            v=${v#*:}
        fi
    done

    unset ip srv gw mask hostname dev autoconf macaddr mtu dns1 dns2
    case $# in
        0)  autoconf="error" ;;
        1)  autoconf=$1 ;;
        2)  [ -n "$1" ] && dev=$1; [ -n "$2" ] && autoconf=$2 ;;
        3)  [ -n "$1" ] && dev=$1; [ -n "$2" ] && autoconf=$2; [ -n "$3" ] && mtu=$3 ;;
        4)  [ -n "$1" ] && dev=$1; [ -n "$2" ] && autoconf=$2; [ -n "$3" ] && mtu=$3; [ -n "$4" ] && macaddr=$4 ;;
        *)  [ -n "$1" ] && ip=$1; [ -n "$2" ] && srv=$2; [ -n "$3" ] && gw=$3; [ -n "$4" ] && mask=$4;
            [ -n "$5" ] && hostname=$5; [ -n "$6" ] && dev=$6; [ -n "$7" ] && autoconf=$7;
            case "$8" in
                [0-9]*:*|[0-9]*.[0-9]*.[0-9]*.[0-9]*)
                    dns1="$8"
                    [ -n "$9" ] && dns2="$9"
                    ;;
                [0-9]*)
                    mtu="$8"
                    ;;
                *)
                    if [ -n "${9}" -a -n "${10}" -a -n "${11}" -a -n "${12}" -a -n "${13}" -a -n "${14}" ]; then
                        macaddr="${9}:${10}:${11}:${12}:${13}:${14}"
                    fi
	            ;;
            esac
            ;;
    esac

    # ip=<ipv4-address> means anaconda-style static config argument cluster:
    # ip=<ip> gateway=<gw> netmask=<nm> hostname=<host> mtu=<mtu>
    # ksdevice={link|bootif|ibft|<MAC>|<ifname>}
    if strglob "$autoconf" "*.*.*.*"; then
        ip="$autoconf"
        gw=$(getarg gateway=)
        mask=$(getarg netmask=)
        hostname=$(getarg hostname=)
        dev=$(getarg ksdevice=)
        autoconf="none"
        mtu=$(getarg mtu=)

        # handle special values for ksdevice
        case "$dev" in
            bootif|BOOTIF) dev=$(fix_bootif $(getarg BOOTIF=)) ;;
            link) dev="" ;; # FIXME: do something useful with this
            ibft) dev="" ;; # ignore - ibft is handled elsewhere
        esac
    fi
}

parse_ifname_opts() {
    local IFS=:
    set $1

    case $# in
        7)
            ifname_if=$1
            # udev requires MAC addresses to be lower case
            ifname_mac=$(echo $2:$3:$4:$5:$6:$7 | sed 'y/ABCDEF/abcdef/')
            ;;
        *)
            die "Invalid arguments for ifname="
            ;;
    esac

    case $ifname_if in
        eth[0-9]|eth[0-9][0-9]|eth[0-9][0-9][0-9]|eth[0-9][0-9][0-9][0-9])
            warn "ifname=$ifname_if uses the kernel name space for interfaces"
            warn "This can fail for multiple network interfaces and is discouraged!"
            warn "Please use a custom name like \"netboot\" or \"bluesocket\""
            warn "or use biosdevname and no ifname= at all."
            ;;
    esac

}

# some network driver need long time to initialize, wait before it's ready.
wait_for_if_link() {
    local cnt=0
    local li
    while [ $cnt -lt 600 ]; do
        li=$(ip -o link show dev $1 2>/dev/null)
        [ -n "$li" ] && return 0
        sleep 0.1
        cnt=$(($cnt+1))
    done
    return 1
}

wait_for_if_up() {
    local cnt=0
    local li
    while [ $cnt -lt 200 ]; do
        li=$(ip -o link show up dev $1)
        [ -n "$li" ] && [ -z "${li##*state UP*}" ] && return 0
        sleep 0.1
        cnt=$(($cnt+1))
    done
    return 1
}

wait_for_route_ok() {
    local cnt=0
    while [ $cnt -lt 200 ]; do
        li=$(ip route show)
        [ -n "$li" ] && [ -z "${li##*$1*}" ] && return 0
        sleep 0.1
        cnt=$(($cnt+1))
    done
    return 1
}

wait_for_ipv6_dad() {
    local cnt=0
    local li
    while [ $cnt -lt 500 ]; do
        li=$(ip -6 addr show dev $1)
        strstr "$li" "tentative" || return 0
        sleep 0.1
        cnt=$(($cnt+1))
    done
    return 1
}

wait_for_ipv6_auto() {
    local cnt=0
    local li
    while [ $cnt -lt 400 ]; do
        li=$(ip -6 addr show dev $1)
        if ! strstr "$li" "tentative"; then
            strstr "$li" "dynamic" && return 0
        fi
        sleep 0.1
        cnt=$(($cnt+1))
    done
    return 1
}

linkup() {
    wait_for_if_link $1 2>/dev/null\
     && ip link set $1 up 2>/dev/null\
     && wait_for_if_up $1 2>/dev/null
}

type hostname >/dev/null 2>&1 || \
hostname() {
	cat /proc/sys/kernel/hostname
}

iface_has_link() {
    local interface="$1" flags=""
    [ -n "$interface" ] || return 2
    interface="/sys/class/net/$interface"
    [ -d "$interface" ] || return 2
    linkup "$1"
    [ "$(cat $interface/carrier)" = 1 ] || return 1
    # XXX Do we need to reset the flags here? anaconda never bothered..
}

find_iface_with_link() {
    local iface_path="" iface=""
    for iface_path in /sys/class/net/*; do
        iface=${iface_path##*/}
        str_starts "$iface" "lo" && continue
        if iface_has_link $iface; then
            echo "$iface"
            return 0
        fi
    done
    return 1
}

is_persistent_ethernet_name() {
    case "$1" in
        # udev persistent interface names
        eth[0-9]|eth[0-9][0-9]|eth[0-9][0-9][0-9]*)
            ;;
        eno[0-9]|eno[0-9][0-9]|eno[0-9][0-9][0-9]*)
            ;;
        ens[0-9]|ens[0-9][0-9]|ens[0-9][0-9][0-9]*)
            ;;
        enp[0-9]s[0-9]*|enp[0-9][0-9]s[0-9]*|enp[0-9][0-9][0-9]*s[0-9]*)
            ;;
        enP*p[0-9]s[0-9]*|enP*p[0-9][0-9]s[0-9]*|enP*p[0-9][0-9][0-9]*s[0-9]*)
            ;;
        # biosdevname
        em[0-9]|em[0-9][0-9]|em[0-9][0-9][0-9]*)
            ;;
        p[0-9]p[0-9]*|p[0-9][0-9]p[0-9]*|p[0-9][0-9][0-9]*p[0-9]*)
            ;;
        *)
            return 1
    esac
    return 0
}
