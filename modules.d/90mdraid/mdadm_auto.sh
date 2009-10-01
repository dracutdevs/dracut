#!/bin/sh
. /lib/dracut-lib.sh

info "Autoassembling MD Raid"    
/sbin/mdadm -As --auto=yes --run 2>&1 | vinfo
