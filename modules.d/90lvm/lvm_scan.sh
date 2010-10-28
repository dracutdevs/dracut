#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# run lvm scan if udev has settled

. /lib/dracut-lib.sh

VGS=$(getargs rd.lvm.vg rd_LVM_VG=)
LVS=$(getargs rd.lvm.lv rd_LVM_LV=)
SNAPSHOT=$(getargs rd.lvm.snapshot rd_LVM_SNAPSHOT=)
SNAPSIZE=$(getargs rd.lvm.snapsize rd_LVM_SNAPSIZE=)

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

        # establish LVM locking
        if [ -n $SNAPSHOT ]; then
            echo 'global {';
            echo '    locking_type = 1';
            echo '}';
        else
            echo 'global {';
            echo '    locking_type = 4';
            echo '}';
        fi
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
    lvm version 2>/dev/null | ( \
        IFS=. read maj min sub; 
        maj=${maj##*:}; 
        sub=${sub%% *}; sub=${sub%%\(*}; 
        check_lvm_ver $maj $min $sub && \
            echo " --poll n ";
    ) 2>/dev/null 
)

if [ -n "$SNAPSHOT" ] ; then
    # HACK - this should probably be done elsewhere or turned into a function
    # Enable read-write LVM locking
    sed -i -e 's/\(^[[:space:]]*\)locking_type[[:space:]]*=[[:space:]]*[[:digit:]]/\1locking_type =  1/' ${initdir}/etc/lvm/lvm.conf

    # Expected SNAPSHOT format "<orig lv name>:<snap lv name>"
    ORIG_LV=${SNAPSHOT%%:*}
    SNAP_LV=${SNAPSHOT##*:}

    info "Removing existing LVM snapshot $SNAP_LV"
    lvm lvremove --force $SNAP_LV 2>&1| vinfo

    # Determine snapshot size
    if [ -z "$SNAPSIZE" ] ; then
        SNAPSIZE=$(lvm lvs --noheadings  --units m --options lv_size $ORIG_LV)
        info "No LVM snapshot size provided, using size of $ORIG_LV ($SNAPSIZE)"
    fi

    info "Creating LVM snapshot $SNAP_LV ($SNAPSIZE)"
    lvm lvcreate -s -n $SNAP_LV -L $SNAPSIZE $ORIG_LV 2>&1| vinfo
fi

if [ -n "$LVS" ] ; then
    info "Scanning devices $lvmdevs for LVM logical volumes $LVS"
    lvm lvscan --ignorelockingfailure 2>&1 | vinfo
    lvm lvchange -ay --ignorelockingfailure $nopoll --ignoremonitoring $LVS 2>&1 | vinfo
fi

if [ -z "$LVS" -o -n "$VGS" ]; then
    info "Scanning devices $lvmdevs for LVM volume groups $VGS"
    lvm vgscan --ignorelockingfailure 2>&1 | vinfo
    lvm vgchange -ay --ignorelockingfailure $nopoll --ignoremonitoring $VGS 2>&1 | vinfo
fi

if [ "$lvmwritten" ]; then
    rm -f /etc/lvm/lvm.conf
    ln -s /sbin/lvm-cleanup /pre-pivot/30-lvm-cleanup.sh 2>/dev/null
    ln -s /sbin/lvm-cleanup /pre-pivot/31-lvm-cleanup.sh 2>/dev/null
fi
unset lvmwritten
