#!/bin/sh
# FIXME: load selinux policy.  this should really be done after we switchroot 

if [ -x "$NEWROOT/usr/sbin/load_policy" -o -x "$NEWROOT/sbin/load_policy" ]; then
    ret=0
    info "Loading SELinux policy"
    {
        # load_policy does mount /proc and /selinux in libselinux,selinux_init_load_policy()
        if [ -x "$NEWROOT/sbin/load_policy" ]; then
            chroot "$NEWROOT" /sbin/load_policy -i
            ret=$?
        else
            chroot "$NEWROOT" /usr/sbin/load_policy -i
            ret=$?
        fi
    } 2>&1 | vinfo

    if [ $ret -eq 3 ]; then
	warn "Initial SELinux policy load failed and enforcing mode requested."
	warn "Not continuing"
	sleep 100d
	exit 1
    fi
fi
