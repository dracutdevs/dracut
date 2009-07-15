#!/bin/sh

if $UDEV_QUEUE_EMPTY >/dev/null 2>&1; then
    [ -h "$job" ] && rm -f "$job"
    # run lvm scan if udev has settled

    VGS=$(getargs rd_LVM_VG=)

    [ -d /etc/lvm ] || mkdir -p /etc/lvm
    # build a list of devices to scan
    lvmdevs=$(
	for f in /tmp/.lvm_scan-*; do
	    [ -e "$f" ] || continue
	    echo -n "${f##/tmp/.lvm_scan-} "
	done
	)
    {
	echo 'devices {';
	echo -n '    filter = [ '
	for dev in $lvmdevs; do
	    printf '"a|^/dev/%s$|", ' $dev;
	done;
	echo '"r/.*/" ]';
	echo 'types = [ "blkext", 1024 ]'
	echo '}';	  
    } > /etc/lvm/lvm.conf

    info "Scanning devices $lvmdevs for LVM volume groups $VGS"
    lvm vgscan 2>&1 | vinfo
    lvm vgchange -ay $VGS 2>&1 | vinfo
fi

