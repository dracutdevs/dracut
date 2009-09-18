#!/bin/sh
. /lib/dracut-lib.sh

info "Autoassembling MD Raid"    
/sbin/mdadm -As --auto=yes --run 2>&1 | vinfo
ln -s /sbin/mdraid-cleanup /pre-pivot/30-mdraid-cleanup.sh 2>/dev/null
ln -s /sbin/mdraid-cleanup /pre-pivot/31-mdraid-cleanup.sh 2>/dev/null
