#!/bin/sh

# run lvm scan if udev has settled

extraargs="$*"
type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

VGS=$(getargs rd.lvm.vg -d rd_LVM_VG=)
LVS=$(getargs rd.lvm.lv -d rd_LVM_LV=)

# shellcheck disable=SC2174
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
        echo 'devices {'
        printf '    filter = [ '
        for dev in $lvmdevs; do
            printf '"a|^/dev/%s$|", ' "$dev"
        done
        echo '"r/.*/" ]'
        echo '}'

        echo 'global {'
        echo '}'
    } > /etc/lvm/lvm.conf
    lvmwritten=1
fi

check_lvm_ver() {
    maj=$1
    min=$2
    ver=$3
    # --poll is supported since 2.2.57
    [ "$4" -lt "$maj" ] && return 1
    [ "$4" -gt "$maj" ] && return 0
    [ "$5" -lt "$min" ] && return 1
    [ "$5" -gt "$min" ] && return 0
    [ "$6" -ge "$ver" ] && return 0
    return 1
}

# hopefully this output format will never change, e.g.:
#   LVM version:     2.02.53(1) (2009-09-25)
OLDIFS=$IFS
IFS=.
# shellcheck disable=SC2046
set -- $(lvm version 2> /dev/null)
IFS=$OLDIFS
maj=${1##*:}
min=$2
sub=${3%% *}
sub=${sub%%\(*}

# For lvchange and vgchange use --sysinit which:
# disables polling (--poll n)
# ignores monitoring (--ignoremonitoring)
# ignores locking failures (--ignorelockingfailure)
# disables hints (--nohints)
#
# For lvscan and vgscan:
# disable locking (--nolocking)
# disable hints (--nohints)

activate_args="--sysinit $extraargs"
unset extraargs

export LVM_SUPPRESS_LOCKING_FAILURE_MESSAGES=1

scan_args="--nolocking"

check_lvm_ver 2 3 14 "$maj" "$min" "$sub" \
    && scan_args="$scan_args --nohints"

if [ -n "$LVS" ]; then
    info "Scanning devices $lvmdevs for LVM logical volumes $LVS"
    # shellcheck disable=SC2086
    lvm lvscan $scan_args 2>&1 | vinfo
    for LV in $LVS; do
        # shellcheck disable=SC2086
        lvm lvchange --yes -K -ay $activate_args "$LV" 2>&1 | vinfo
    done
fi

if [ -z "$LVS" ] || [ -n "$VGS" ]; then
    info "Scanning devices $lvmdevs for LVM volume groups $VGS"
    # shellcheck disable=SC2086
    lvm vgscan $scan_args 2>&1 | vinfo
    # shellcheck disable=SC2086
    lvm vgchange -ay $activate_args $VGS 2>&1 | vinfo
fi

if [ "$lvmwritten" ]; then
    rm -f -- /etc/lvm/lvm.conf
fi
unset lvmwritten

udevadm settle

need_shutdown
