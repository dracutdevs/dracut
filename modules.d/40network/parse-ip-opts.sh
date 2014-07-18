#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Format:
#       ip=[dhcp|on|any]
#
#       ip=<interface>:[dhcp|on|any][:[<mtu>][:<macaddr>]]
#
#       ip=<client-IP-number>:<server-IP-number>:<gateway-IP-number>:<netmask>:<client-hostname>:<interface>:{dhcp|on|any|none|off}[:[<mtu>][:<macaddr>]]
#
# When supplying more than only ip= line, <interface> is mandatory and
# bootdev= must contain the name of the primary interface to use for
# routing,dns,dhcp-options,etc.
#

command -v getarg >/dev/null          || . /lib/dracut-lib.sh

if [ -n "$netroot" ] && [ -z "$(getarg ip=)" ] && [ -z "$(getarg BOOTIF=)" ]; then
    # No ip= argument(s) for netroot provided, defaulting to DHCP
    return;
fi

# Count ip= lines to decide whether we need bootdev= or not
if [ -z "$NEEDBOOTDEV" ] ; then
    count=0
    for p in $(getargs ip=); do
        case "$p" in
            ibft)
                continue;;
        esac
        count=$(( $count + 1 ))
    done
    [ $count -gt 1 ] && NEEDBOOTDEV=1
fi
unset count

# If needed, check if bootdev= contains anything usable
BOOTDEV=$(getarg bootdev=)

if [ -n "$NEEDBOOTDEV" ] ; then
    [ -z "$BOOTDEV" ] && warn "Please supply bootdev argument for multiple ip= lines"
fi

# Check ip= lines
# XXX Would be nice if we could errorcheck ip addresses here as well
for p in $(getargs ip=); do
    ip_to_var $p

    # make first device specified the BOOTDEV
    if [ -z "$BOOTDEV" ] && [ -n "$dev" ]; then
        BOOTDEV="$dev"
        [ -n "$NEEDBOOTDEV" ] && warn "Setting bootdev to '$BOOTDEV'"
    fi

    # skip ibft since we did it above
    [ "$autoconf" = "ibft" ] && continue

    # We need to have an ip= line for the specified bootdev
    [ -n "$NEEDBOOTDEV" ] && [ "$dev" = "$BOOTDEV" ] && BOOTDEVOK=1

    # Empty autoconf defaults to 'dhcp'
    if [ -z "$autoconf" ] ; then
        warn "Empty autoconf values default to dhcp"
        autoconf="dhcp"
    fi

    # Error checking for autoconf in combination with other values
    case $autoconf in
        error) die "Error parsing option 'ip=$p'";;
        bootp|rarp|both) die "Sorry, ip=$autoconf is currenty unsupported";;
        none|off)
            [ -z "$ip" ] && \
            die "For argument 'ip=$p'\nValue '$autoconf' without static configuration does not make sense"
            [ -z "$mask" ] && \
                die "Sorry, automatic calculation of netmask is not yet supported"
            ;;
        auto6);;
        dhcp|dhcp6|on|any) \
            [ -n "$NEEDBOOTDEV" ] && [ -z "$dev" ] && \
            die "Sorry, 'ip=$p' does not make sense for multiple interface configurations"
            [ -n "$ip" ] && \
                die "For argument 'ip=$p'\nSorry, setting client-ip does not make sense for '$autoconf'"
            ;;
        *) die "For argument 'ip=$p'\nSorry, unknown value '$autoconf'";;
    esac

    if [ -n "$dev" ] ; then
        # We don't like duplicate device configs
        if [ -n "$IFACES" ] ; then
            for i in $IFACES ; do
                [ "$dev" = "$i" ] && die "For argument 'ip=$p'\nDuplication configurations for '$dev'"
            done
        fi
        # IFACES list for later use
        IFACES="$IFACES $dev"
    fi

    # Do we need to check for specific options?
    if [ -n "$NEEDDHCP" ] || [ -n "$DHCPORSERVER" ] ; then
        # Correct device? (Empty is ok as well)
        [ "$dev" = "$BOOTDEV" ] || continue
        # Server-ip is there?
        [ -n "$DHCPORSERVER" ] && [ -n "$srv" ] && continue
        # dhcp? (It's simpler to check for a set ip. Checks above ensure that if
        # ip is there, we're static
        [ -z "$ip" ] && continue
        # Not good!
        die "Server-ip or dhcp for netboot needed, but current arguments say otherwise"
    fi

done

# put BOOTIF in IFACES to make sure it comes up
if getargbool 1 "rd.bootif" && BOOTIF="$(getarg BOOTIF=)"; then
    BOOTDEV=$(fix_bootif $BOOTIF)
    IFACES="$BOOTDEV $IFACES"
fi

# This ensures that BOOTDEV is always first in IFACES
if [ -n "$BOOTDEV" ] && [ -n "$IFACES" ] ; then
    IFACES="${IFACES%$BOOTDEV*} ${IFACES#*$BOOTDEV}"
    IFACES="$BOOTDEV $IFACES"
fi

# Store BOOTDEV and IFACES for later use
[ -n "$BOOTDEV" ] && echo $BOOTDEV > /tmp/net.bootdev
[ -n "$IFACES" ]  && echo $IFACES > /tmp/net.ifaces
