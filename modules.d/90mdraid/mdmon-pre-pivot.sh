# switch any mdmon instances to newroot
[ -f /etc/mdadm.conf ] && /sbin/mdmon /proc/mdstat $NEWROOT

