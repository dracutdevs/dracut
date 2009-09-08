#!/bin/sh
# FIXME: load selinux policy.  this should really be done after we switchroot 

if [ -x "$NEWROOT/usr/sbin/load_policy" -o -x "$NEWROOT/sbin/load_policy" ] && [ -e "$NEWROOT/etc/sysconfig/selinux" ]; then
    info "Loading SELinux policy"
    {
    chroot "$NEWROOT" /bin/mount -t selinuxfs selinuxfs /selinux
    chroot "$NEWROOT" /bin/mount -t proc proc  /proc

    if [ -x "$NEWROOT/sbin/load_policy" ]; then
        chroot "$NEWROOT" /sbin/load_policy -i 2>&1
    else
        chroot "$NEWROOT" /usr/sbin/load_policy -i 2>&1
    fi

    if [ $? -eq 3 ]; then
	warn "Initial SELinux policy load failed and enforcing mode requested."
	warn "Not continuing"
	sleep 100d
	exit 1
    fi
    chroot "$NEWROOT" /bin/umount /proc
    } | vinfo
fi
