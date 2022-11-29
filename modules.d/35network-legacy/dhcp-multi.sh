#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
PATH=/usr/sbin:/usr/bin:/sbin:/bin

# File to start dhclient requests on different interfaces in parallel

. /lib/dracut-lib.sh
. /lib/net-lib.sh

netif=$1
do_vlan=$2
arg=$3

# Run dhclient in parallel
do_dhclient() {
    local _COUNT=0
    local _timeout
    local _DHCPRETRY
    _timeout=$(getarg rd.net.timeout.dhcp=)
    _DHCPRETRY=$(getargnum 1 1 1000000000 rd.net.dhcp.retry=)

    if [ -n "$_timeout" ]; then
        if ! (dhclient --help 2>&1 | grep -q -F -- '--timeout' 2> /dev/null); then
            warn "rd.net.timeout.dhcp has no effect because dhclient does not implement the --timeout option"
            unset _timeout
        fi
    fi

    while [ $_COUNT -lt "$_DHCPRETRY" ]; do
        info "Starting dhcp for interface $netif"
        dhclient "$arg" \
            ${_timeout:+--timeout "$_timeout"} \
            -q \
            -1 \
            -cf /etc/dhclient.conf \
            -pf /tmp/dhclient."$netif".pid \
            -lf /tmp/dhclient."$netif".lease \
            "$netif" &
        wait $! 2> /dev/null

        # wait will return the return value of dhclient
        retv=$?

        # dhclient and hence wait returned success, 0.
        if [ $retv -eq 0 ]; then
            return 0
        fi

        # If dhclient exited before wait was called, or it was killed by
        # another thread for interface whose DHCP succeeded, then it will not
        # find the process with that pid and return error code 127. In that
        # case we need to check if /tmp/dhclient.$netif.lease exists. If it
        # does, it means dhclient finished executing before wait was called,
        # and it was successful (return 0). If /tmp/dhclient.$netif.lease
        # does not exist, then it means dhclient was killed by another thread
        # or it finished execution but failed dhcp on that interface.

        if [ $retv -eq 127 ]; then
            read -r pid < /tmp/dhclient."$netif".pid
            info "PID $pid was not found by wait for $netif"
            if [ -e /tmp/dhclient."$netif".lease ]; then
                info "PID $pid not found but DHCP successful on $netif"
                return 0
            fi
        fi

        _COUNT=$((_COUNT + 1))
        [ $_COUNT -lt "$_DHCPRETRY" ] && sleep 1
    done
    warn "dhcp for interface $netif failed"
    # nuke those files since we failed; we might retry dhcp again if it's e.g.
    # `ip=dhcp,dhcp6` and we check for the PID file earlier
    rm -f /tmp/dhclient."$netif".pid /tmp/dhclient."$netif".lease
    return 1
}

do_dhclient
ret=$?

# setup nameserver
for s in "$dns1" "$dns2" $(getargs nameserver); do
    [ -n "$s" ] || continue
    echo nameserver "$s" >> /tmp/net."$netif".resolv.conf
done

if [ $ret -eq 0 ]; then
    : > /tmp/net."${netif}".up

    if [ -z "$do_vlan" ] && [ -e /sys/class/net/"${netif}"/address ]; then
        : > "/tmp/net.$(cat /sys/class/net/"${netif}"/address).up"
    fi

    # Check if DHCP also suceeded on another interface before this one.
    # We will always use the first one on which DHCP succeeded, by using
    # a commom file $IFNETFILE, to synchronize between threads.
    # Consider the race condition in which multiple threads
    # corresponding to different interfaces may try to read $IFNETFILE
    # and find it does not exist; they may all end up thinking they are the
    # first to succeed (hence more than one thread may end up writing to
    # $IFNETFILE). To take care of this, instead of checking if $IFNETFILE
    # exists to determine if we are the first, we create a symbolic link
    # in $IFNETFILE, pointing to the interface name ($netif), thus storing
    # the interface name in the link pointer.
    # Creating a link will fail, if the link already exists, hence kernel
    # will take care of allowing only first thread to create link, which
    # takes care of the race condition for us. Subsequent threads will fail.
    # Also, the link points to the interface name, which will tell us which
    # interface succeeded.

    if ln -s "$netif" "$IFNETFILE" 2> /dev/null; then
        intf=$(readlink "$IFNETFILE")
        if [ -e /tmp/dhclient."$intf".lease ]; then
            info "DHCP successful on interface $intf"
            # Kill all existing dhclient calls for other interfaces, since we
            # already got one successful interface

            read -r npid < /tmp/dhclient."$netif".pid
            pidlist=$(pgrep dhclient)
            for pid in $pidlist; do
                [ "$pid" -eq "$npid" ] && continue
                kill -9 "$pid" > /dev/null 2>&1
            done
        else
            echo "ERROR! $IFNETFILE exists but /tmp/dhclient.$intf.lease does not exist!!!"
        fi
    else
        info "DHCP success on $netif, and also on $intf"
        exit 0
    fi
    exit $ret
fi
