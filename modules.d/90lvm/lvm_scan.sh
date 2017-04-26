#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# run lvm scan if udev has settled

extraargs="$@"
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

VGS=$(getargs rd.lvm.vg -d rd_LVM_VG=)
LVS=$(getargs rd.lvm.lv -d rd_LVM_LV=)
SNAPSHOT=$(getargs rd.lvm.snapshot -d rd_LVM_SNAPSHOT=)
SNAPSIZE=$(getargs rd.lvm.snapsize -d rd_LVM_SNAPSIZE=)

[ -d /etc/lvm ] || mkdir -m 0755 -p /etc/lvm
# build a list of devices to scan
lvmdevs=$(
    for f in /tmp/.lvm_scan-*; do
        [ -e "$f" ] || continue
        printf '%s' "${f##/tmp/.lvm_scan-} "
    done
)

if [ ! -e /etc/lvm/lvm.conf ]; then
    {
        echo 'devices {';
        printf '    filter = [ '
        for dev in $lvmdevs; do
            printf '"a|^/dev/%s$|", ' $dev;
        done;
        echo '"r/.*/" ]';
        echo '}';

        # establish LVM locking
        if [ -n $SNAPSHOT ]; then
            echo 'global {';
            echo '    locking_type = 1';
            echo '    use_lvmetad = 0';
            echo '}';
        else
            echo 'global {';
            echo '    locking_type = 4';
            echo '    use_lvmetad = 0';
            echo '}';
        fi
    } > /etc/lvm/lvm.conf
    lvmwritten=1
fi

check_lvm_ver() {
    maj=$1
    min=$2
    ver=$3
    # --poll is supported since 2.2.57
    [ $4 -lt $maj ] && return 1
    [ $4 -gt $maj ] && return 0
    [ $5 -lt $min ] && return 1
    [ $5 -gt $min ] && return 0
    [ $6 -ge $ver ] && return 0
    return 1
}

# hopefully this output format will never change, e.g.:
#   LVM version:     2.02.53(1) (2009-09-25)
OLDIFS=$IFS
IFS=.
set $(lvm version 2>/dev/null)
IFS=$OLDIFS
maj=${1##*:}
min=$2
sub=${3%% *}
sub=${sub%%\(*};

check_lvm_ver 2 2 57 $maj $min $sub && \
    nopoll="--poll n"

if check_lvm_ver 2 2 65 $maj $min $sub; then
    sysinit=" --sysinit $extraargs"
fi

unset extraargs

export LVM_SUPPRESS_LOCKING_FAILURE_MESSAGES=1

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
    for LV in $LVS; do
        if [ -z "$sysinit" ]; then
            lvm lvchange --yes -K -ay --ignorelockingfailure $nopoll --ignoremonitoring $LV 2>&1 | vinfo
        else
            lvm lvchange --yes -K -ay $sysinit $LV 2>&1 | vinfo
        fi
    done
fi

if [ -z "$LVS" -o -n "$VGS" ]; then
    info "Scanning devices $lvmdevs for LVM volume groups $VGS"
    lvm vgscan --ignorelockingfailure 2>&1 | vinfo
    if [ -z "$sysinit" ]; then
        lvm vgchange -ay --ignorelockingfailure $nopoll --ignoremonitoring $VGS 2>&1 | vinfo
    else
        lvm vgchange -ay $sysinit $VGS 2>&1 | vinfo
    fi
fi

if [ "$lvmwritten" ]; then
    rm -f -- /etc/lvm/lvm.conf
fi
unset lvmwritten

udevadm settle

need_shutdown
