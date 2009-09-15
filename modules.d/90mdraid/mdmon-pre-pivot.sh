# switch any mdmon instances to newroot
if  pidof mdmon >/dev/null 2>&1; then
    /sbin/mdmon /proc/mdstat $NEWROOT
fi

