#!/bin/sh

# pxelinux provides macaddr '-' separated, but we need ':'
fix_bootif() {
    local macaddr=${1}
    local IFS='-'
    macaddr=$(for i in ${macaddr} ; do echo -n $i:; done)
    macaddr=${macaddr%:}
    echo $macaddr
}

# Don't continue if we don't need network
[ -z "$netroot" ] && return;

# Write udev rules
{

    # BOOTIF says everything, use only that one
    BOOTIF=$(getarg 'BOOTIF=')
    if [ -n "$BOOTIF" ] ; then
	BOOTIF=$(fix_bootif "$BOOTIF")
	printf 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="%s", RUN+="/sbin/initqueue /sbin/ifup $env{INTERFACE}"\n' "$BOOTIF"

    # If we have to handle multiple interfaces, handle only them.
    elif [ -n "$IFACES" ] ; then
	for iface in $IFACES ; do
	    printf 'ACTION=="add", SUBSYSTEM=="net", KERNEL=="%s", RUN+="/sbin/initqueue /sbin/ifup $env{INTERFACE}"\n' "$iface"
	done

    # Default: We don't know the interface to use, handle all
    else
	printf 'ACTION=="add", SUBSYSTEM=="net", RUN+="/sbin/initqueue /sbin/ifup $env{INTERFACE}"\n'
    fi

    # Udev event 'online' only gets fired from ifup/dhclient-script.
    # No special rules required
    printf 'ACTION=="online", SUBSYSTEM=="net", RUN+="/sbin/initqueue /sbin/netroot $env{INTERFACE}"\n'
} > /etc/udev/rules.d/60-net.rules
