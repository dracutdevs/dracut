#!/bin/sh

# run lvm scan if udev has settled

. /lib/dracut-lib.sh

VGS=$(getargs rd_LVM_VG=)

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
	echo 'types = [ "blkext", 1024 , "cciss0", 1024 ]'
	echo '}';	  
    } > /etc/lvm/lvm.conf
    lvmwritten=1
fi
info "Scanning devices $lvmdevs for LVM volume groups $VGS"
lvm vgscan 2>&1 | vinfo
lvm vgchange -ay $VGS 2>&1 | vinfo
if [ "$lvmwritten" ]; then
    rm -f /etc/lvm/lvm.conf
    ln -s /sbin/lvm-cleanup /pre-pivot/30-lvm-cleanup.sh 2>/dev/null
    ln -s /sbin/lvm-cleanup /pre-pivot/31-lvm-cleanup.sh 2>/dev/null
fi
unset lvmwritten
