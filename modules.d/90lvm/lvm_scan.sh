#!/bin/sh

# run lvm scan if udev has settled

. /lib/dracut-lib.sh

VGS=$(getargs rd_LVM_VG=)
LVS=$(getargs rd_LVM_LV=)

[ -d /etc/lvm ] || mkdir -p /etc/lvm
# build a list of devices to scan
lvmdevs=$(
    for f in /tmp/.lvm_scan-*; do
	[ -e "$f" ] || continue
	echo -n "${f##/tmp/.lvm_scan-} "
    done
)

if [ ! -e /etc/lvm/lvm.conf ]; then 
    {
	echo 'devices {';
	echo -n '    filter = [ '
	for dev in $lvmdevs; do
	    printf '"a|^/dev/%s$|", ' $dev;
	done;
	echo '"r/.*/" ]';
	echo '}';	  
	# establish read-only locking
	echo 'global {';
	echo '    locking_type = 4';
	echo '}';
    } > /etc/lvm/lvm.conf
    lvmwritten=1
fi

check_lvm_ver() {
    # --poll is supported since 2.2.57
    [ $1 -lt 2 ] && return 1
    [ $1 -gt 2 ] && return 0
    # major is 2
    [ $2 -lt 2 ] && return 1
    [ $2 -gt 2 ] && return 0
    # minor is 2, check for 
    # greater or equal 57
    [ $3 -ge 57 ] && return 0
    return 1
}

nopoll=$(
    # hopefully this output format will never change, e.g.:
    #   LVM version:     2.02.53(1) (2009-09-25)
    lvm version 2>/dev/null | \
	(
	IFS=. read maj min sub; 
	maj=${maj##*:}; 
	sub=${sub%% *}; sub=${sub%%\(*}; 
	check_lvm_ver $maj $min $sub && \
	    echo " --poll n "))

if [ -n "$LVS" ] ; then
    info "Scanning devices $lvmdevs for LVM logical volumes $LVS"
    lvm lvscan --ignorelockingfailure 2>&1 | vinfo
    lvm lvchange -ay --ignorelockingfailure $nopoll --monitor n $LVS 2>&1 | vinfo    
fi

if [ -z "$LVS" -o -n "$VGS" ]; then
    info "Scanning devices $lvmdevs for LVM volume groups $VGS"
    lvm vgscan --ignorelockingfailure 2>&1 | vinfo
    lvm vgchange -ay --ignorelockingfailure $nopoll --monitor n $VGS 2>&1 | vinfo
fi

if [ "$lvmwritten" ]; then
    rm -f /etc/lvm/lvm.conf
    ln -s /sbin/lvm-cleanup /pre-pivot/30-lvm-cleanup.sh 2>/dev/null
    ln -s /sbin/lvm-cleanup /pre-pivot/31-lvm-cleanup.sh 2>/dev/null
fi
unset lvmwritten
