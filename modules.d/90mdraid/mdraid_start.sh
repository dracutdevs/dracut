#!/bin/sh

. /lib/dracut-lib.sh
# run mdadm if udev has settled
info "Assembling MD RAID arrays"
mdadm -IRs 2>&1 | vinfo
