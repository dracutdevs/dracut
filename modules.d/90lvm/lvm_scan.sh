#!/bin/sh

# run lvm scan if udev has settled

extraargs="$*"
type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

VGS=$(getargs rd.lvm.vg -d rd_LVM_VG=)
LVS=$(getargs rd.lvm.lv -d rd_LVM_LV=)

# shellcheck disable=SC2174
[ -d /etc/lvm ] || mkdir -m 0755 -p /etc/lvm
[ -d /run/lvm ] || mkdir -m 0755 -p /run/lvm
# build a list of devices to scan
lvmdevs=$(
    for f in /tmp/.lvm_scan-*; do
        [ -e "$f" ] || continue
        printf '%s' "${f##/tmp/.lvm_scan-} "
    done
)

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

no_lvm_conf_filter() {
    if [ ! -e /etc/lvm/lvm.conf ]; then
        return 0
    fi

    if [ -e /run/lvm/initrd_no_filter ]; then
        return 0
    fi

    if [ -e /run/lvm/initrd_filter ]; then
        return 1
    fi

    if [ -e /run/lvm/initrd_global_filter ]; then
        return 1
    fi

    # Save lvm config results in /run to avoid running
    # lvm config commands for every PV that's scanned.

    filter=$(lvm config devices/filter | grep "$filter=")
    if [ -n "$filter" ]; then
        printf '%s\n' "$filter" > /run/lvm/initrd_filter
        return 1
    fi

    global_filter=$(lvm config devices/global_filter | grep "$global_filter=")
    if [ -n "$global_filter" ]; then
        printf '%s\n' "$global_filter" > /run/lvm/initrd_global_filter
        return 1
    fi

    # /etc/lvm/lvm.conf exists with no filter setting
    true > /run/lvm/initrd_no_filter
    return 0
}

# If no lvm.conf exists, create a basic one with a global section.
if [ ! -e /etc/lvm/lvm.conf ]; then
    {
        echo 'global {'
        echo '}'
    } > /etc/lvm/lvm.conf
    lvmwritten=1
fi

# Save the original lvm.conf before appending a filter setting.
if [ ! -e /etc/lvm/lvm.conf.orig ]; then
    cp /etc/lvm/lvm.conf /etc/lvm/lvm.conf.orig
fi

# If the original lvm.conf does not contain a filter setting,
# then generate a filter and append it to the original lvm.conf.
# The filter is generated from the list PVs that have been seen
# so far (each has been processed by the lvm udev rule.)
if no_lvm_conf_filter; then
    {
        echo 'devices {'
        printf '    filter = [ '
        for dev in $lvmdevs; do
            printf '"a|^/dev/%s$|", ' "$dev"
        done
        echo '"r/.*/" ]'
        echo '}'
    } > /etc/lvm/lvm.conf.filter
    lvmfilter=1
    cat /etc/lvm/lvm.conf.orig /etc/lvm/lvm.conf.filter > /etc/lvm/lvm.conf
fi

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
# For lvs and vgscan:
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
    LVSLIST=$(lvm lvs $scan_args --noheading -o lv_full_name,segtype $LVS)
    info "$LVSLIST"

    # Only attempt to activate an LV if it appears in the lvs output.
    for LV in $LVS; do
        if strstr "$LVSLIST" "$LV"; then
            # This lvchange is expected to fail if all PVs used by
            # the LV are not yet present.  Premature/failed lvchange
            # could be avoided by reporting if an LV is complete
            # from the lvs command above and skipping this lvchange
            # if the LV is not lised as complete.
            # shellcheck disable=SC2086
            lvm lvchange --yes -K -ay $activate_args "$LV" 2>&1 | vinfo
        fi
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
elif [ "$lvmfilter" ]; then
    # revert filter that was appended to existing lvm.conf
    cp /etc/lvm/lvm.conf.orig /etc/lvm/lvm.conf
    rm -f -- /etc/lvm/lvm.conf.filter
fi
unset lvmwritten
unset lvmfilter

udevadm settle

need_shutdown
