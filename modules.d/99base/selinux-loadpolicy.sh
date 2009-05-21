#!/bin/sh
# FIXME: load selinux policy.  this should really be done after we switchroot 
[ -x "$NEWROOT/usr/sbin/load_policy" ] && [ -x "$NEWROOT/etc/sysconfig/selinux" ] {
    chroot $NEWROOT /usr/sbin/load_policy -i
    if [ $? -eq 3 ]; then
	echo "Initial SELinux policy load failed and enforcing mode requested."
	echo "Not continuing"
	sleep 100d
	exit 1
    fi
}
