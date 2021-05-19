#!/bin/bash

# pvscan wrapper called by initrd lvm udev rule to find the
# intersection of complete VGs/LVs found by pvscan and the
# requested VGs/LVs from the cmdline.
#
# Used in 64-lvm.rules as:
# IMPORT{program}="pvscan-udev-initrd.sh $env{DEVNAME}"
#
# See /usr/lib/dracut/modules.d/90lvm/64-lvm.rules

dev=$1

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

VGS=$(getargs rd.lvm.vg -d rd_LVM_VG=)
LVS=$(getargs rd.lvm.lv -d rd_LVM_LV=)

IFS=' '

# pvscan will produce a single VG line, and one or more LV lines.
# VG <name> complete
# VG <name> incomplete
# LV <name> complete
# LV <name> incomplete
#
# LV names are printed as vgname/lvname.
# We only care about the complete items.
# Each pvscan will produce a single VG line,
# and may produce zero, one or more LV lines.

PVSCAN=$(/sbin/lvm pvscan --cache --listlvs --checkcomplete --journal output --config 'global/event_activation=1' "$dev")

read -r -a VGSARRAY <<< "$VGS"

for VG in "${VGSARRAY[@]}"; do
    if strstr "$PVSCAN" "VG $VG complete"; then
        echo LVM_VG_NAME_COMPLETE=\'"$VG"\'
    fi
done

# Combine all matching LVs into a single print containing them all,
# e.g. LVM_LV_NAMES_COMPLETE='vg/lv1 vg/lv2'

read -r -a LVSARRAY <<< "$LVS"

printf LVM_LV_NAMES_COMPLETE=\'
for LV in "${LVSARRAY[@]}"; do
    if strstr "$PVSCAN" "LV $LV complete"; then
        printf "%s " $LV
    fi
done
echo \'
