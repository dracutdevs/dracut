#!/bin/sh
#
# Format:
#	ip=[dhcp|on|any]
#
#	ip=<interface>:[dhcp|on|any]
#
#	ip=<client-IP-number>:<server-id>:<gateway-IP-number>:<netmask>:<client-hostname>:<interface>:[dhcp|on|any|none|off]
#

# Sadly there's no easy way to split ':' separated lines into variables
ip_to_var() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
	set -- "$@" "${v%%:*}"
	v=${v#*:}
    done

    unset ip srv gw mask hostname dev autoconf
    case $# in
    0)	autoconf="error" ;;
    1)	autoconf=$1 ;;
    2)	dev=$1; autoconf=$2 ;;
    *)	ip=$1; srv=$2; gw=$3; mask=$4; hostname=$5; dev=$6; autoconf=$7 ;;
    esac
}

# Check if ip= lines should be used
if getarg ip= >/dev/null ; then
    if [ -z "$netroot" ] ; then
	echo "Warning: No netboot configured, ignoring ip= lines"
	return;
    fi
fi

# Don't mix BOOTIF=macaddr from pxelinux and ip= lines
getarg ip= >/dev/null && getarg BOOTIF= >/dev/null && \
    die "Mixing BOOTIF and ip= lines is dangerous"

# No more parsing stuff, BOOTIF says everything
[ -n "$(getarg BOOTIF)" ] && return

# Warn if defaulting to ip=dhcp
if [ -n "$netroot" ] && [ -z "$(getarg ip=)" ] ; then
    warn "No ip= argument(s) for netroot provided, defaulting to DHCP"
    return;
fi

# Check ip= lines
# XXX Would be nice if we could errorcheck ip addresses here as well
[ "$CMDLINE" ] || read CMDLINE < /proc/cmdline
for p in $CMDLINE; do
    [ -n "${p%ip=*}" ] && continue

    ip_to_var ${p#ip=}

    # Empty autoconf defaults to 'dhcp'
    if [ -z "$autoconf" ] ; then
	warn "Empty autoconf values default to dhcp"
	autoconf="dhcp"
    fi

    # Error checking for autoconf in combination with other values
    case $autoconf in
	error) die "Error parsing option '$p'";;
	bootp|rarp|both) die "Sorry, ip=$autoconf is currenty unsupported";;
	none|off) \
	    [ -z "$ip" ] && \
		die "For argument '$p'\nValue '$autoconf' without static configuration does not make sense"
	    [ -z "$mask" ] && \
		die "Sorry, automatic calculation of netmask is not yet supported"
	    ;;
	dhcp|on|any) \
	    [ -n "$ip" ] && \
		die "For argument '$p'\nSorry, setting client-ip does not make sense for '$autoconf'"
	    ;;
	*) die "For argument '$p'\nSorry, unknown value '$autoconf'";;
    esac

    # We don't like duplicate device configs
    if [ -n "$dev" ] ; then
	if [ -n "$IFACES" ] ; then
	    for i in $IFACES ; do
		[ "$dev" = "$i" ] && die "For argument '$p'\nDuplication configurations for '$dev'"
	    done
	fi
	IFACES="$IFACES $dev"
    fi

    # Do we need DHCP? (It's simpler to check for a set ip. Checks above ensure that if
    # ip is there, we're static) 
    [ -n "$NEEDDHCP" ] && [ -z "$ip" ] && DHCPOK="1"

    # Do we need srv OR dhcp?
    if [ -n "$DHCPORSERVER" ] ; then
	[ -n "$DHCPOK" ] && SRVOK="1"
	[ -n "$srv" ] && SRVOK="1"
    fi

done

[ -n "$NEEDDHCP" ] && [ -z "$DHCPOK" ] && die "Server-ip or dhcp for netboot needed, but current arguments say otherwise"

[ -n "$DHCPORSERVER" ] && [ -z "$SRVOK" ] && die "Server-ip or dhcp for netboot needed, but current arguments say otherwise"
