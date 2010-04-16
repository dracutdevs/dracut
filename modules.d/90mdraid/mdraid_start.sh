#!/bin/sh

. /lib/dracut-lib.sh
# run mdadm if udev has settled
info "Assembling MD RAID arrays"
udevadm control --stop-exec-queue
mdadm -IRs 2>&1 | vinfo

# there could still be some leftover devices
# which have had a container added
for md in /dev/md[0-9]* /dev/md/*; do 
	[ -b "$md" ] || continue
	local udevinfo="$(udevadm info --query=env --name=$md)"
	strstr "$udevinfo" "MD_UUID=" && continue
	strstr "$udevinfo" "MD_LEVEL=container" && continue
	strstr "$udevinfo" "DEVTYPE=partition" && continue
	mdadm -R "$md" 2>&1 | vinfo
done

ln -s /sbin/mdraid-cleanup /pre-pivot/30-mdraid-cleanup.sh 2>/dev/null
ln -s /sbin/mdraid-cleanup /pre-pivot/31-mdraid-cleanup.sh 2>/dev/null
udevadm control --start-exec-queue
