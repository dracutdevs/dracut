# We should go last, and default the root if needed

if [ -z "$root" -a -z "$netroot" ]; then
    netroot=dhcp
fi

if [ "$root" = "dhcp" -a -z "$netroot" ]; then
    rootok=1
    netroot=dhcp
    unset root
fi

# Cleanup any coversions from root->netroot if they are the same
if [ "$netroot" = "$root" ]; then
    unset root
fi

if [ "${netroot+set}" = "set" ]; then
    eval "echo netroot='$netroot'" > /tmp/netroot.info
fi
