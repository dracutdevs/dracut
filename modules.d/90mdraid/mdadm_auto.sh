#!/bin/sh
. /lib/dracut-lib.sh

info "Autoassembling MD Raid"    
udevadm control --stop-exec-queue
/sbin/mdadm -As --auto=yes --run 2>&1 | vinfo
udevadm control --start-exec-queue
