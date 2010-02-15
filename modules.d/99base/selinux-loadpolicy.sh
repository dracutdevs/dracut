#!/bin/sh
# FIXME: load selinux policy.  this should really be done after we switchroot 

rd_load_policy()
{

    SELINUX="enforcing"
    [ -e "$NEWROOT/etc/selinux/config" ] && . "$NEWROOT/etc/selinux/config"

    disabled=0
    # If SELinux is disabled exit now 
    getarg "selinux=0" > /dev/null
    if [ $? -eq 0 -o "$SELINUX" = "disabled" ]; then
	disabled=1
    fi

    # Check whether SELinux is in permissive mode
    permissive=0
    getarg "enforcing=0" > /dev/null
    if [ $? -eq 0 -o "$SELINUX" = "permissive" ]; then
	permissive=1
    fi

    # Attempt to load SELinux Policy
    if [ -x "$NEWROOT/usr/sbin/load_policy" -o -x "$NEWROOT/sbin/load_policy" ]; then
	ret=0
	info "Loading SELinux policy"
	{
            # load_policy does mount /proc and /selinux in 
            # libselinux,selinux_init_load_policy()
            if [ -x "$NEWROOT/sbin/load_policy" ]; then
		chroot "$NEWROOT" /sbin/load_policy -i
		ret=$?
            else
		chroot "$NEWROOT" /usr/sbin/load_policy -i
		ret=$?
            fi
	} 2>&1 | vinfo

	if [ $disabled -eq 1 ]; then
	    return 0;
	fi

	if [ $ret -eq 0 -o $ret -eq 2 ]; then
	    # If machine requires a relabel, force to permissive mode
	    [ -e "$NEWROOT"/.autorelabel ] && ( echo 0 > "$NEWROOT"/selinux/enforce )
	    return 0
	fi

	warn "Initial SELinux policy load failed."
	if [ $ret -eq 3 -o $permissive -eq 0 ]; then
	    warn "Machine in enforcing mode."
	    warn "Not continuing"
	    sleep 100d
	    exit 1
	fi
	return 0
    elif [ $permissive -eq 0 ]; then
	warn "Machine in enforcing mode and cannot execute load_policy."
	warn "To disable selinux, add selinux=0 to the kernel command line."
	warn "Not continuing"
	sleep 100d
	exit 1
    fi
}

rd_load_policy
