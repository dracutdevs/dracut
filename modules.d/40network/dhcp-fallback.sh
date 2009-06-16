# We should go last, and default the root if needed

if [ -z "$root" -a -z "$netroot" ]; then
    rootok=1
    root=dhcp
    netroot=dhcp
fi

if [ "$root" = "dhcp" -a -z "$netroot" ]; then
    rootok=1
    netroot=dhcp
fi

if [ "$netroot" = "dhcp" -a -z "$root" ]; then
    rootok=1
    root=dhcp
fi

if [ -n "$NEEDDHCP" ] ; then
    rootok=1
    root=dhcp
    #Don't overwrite netroot here, as it might contain something useful
fi
