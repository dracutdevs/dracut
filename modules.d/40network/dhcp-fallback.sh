# We should go last, and default the root if needed

if [ -z "$root" ]; then
    root=dhcp
fi

if [ "$root" = "dhcp" -a -z "$netroot" ]; then
    rootok=1
    netroot=dhcp
fi

if [ "${netroot+set}" = "set" ]; then
    eval "echo netroot='$netroot'" > /tmp/netroot.info
fi
