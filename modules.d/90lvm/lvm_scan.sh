#!/bin/sh

if $UDEV_QUEUE_EMPTY >/dev/null 2>&1; then
    [ -h "$job" ] && rm -f "$job"
    # run lvm scan if udev has settled

    [ -d /etc/lvm ] || mkdir -p /etc/lvm
    # build a list of devices to scan
    lvmdevs=$(
	for f in /tmp/.lvm_scan-*; do
	    [ -e "$f" ] || continue
	    echo ${f##/tmp/.lvm_scan-}
	done
	)
    {
	echo 'devices {';
	echo -n '    filter = [ '
	for dev in $lvmdevs; do
	    printf '"a|^/dev/%s$|", ' $dev;
	done;
	echo '"r/.*/" ]';
	echo '}';	  
    } > /etc/lvm/lvm.conf

    lvm vgscan
    lvm vgchange -ay
fi

