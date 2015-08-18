#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

dev="$1"
devenc=$(str_replace "$1" '/' '\2f')

[ -e /tmp/dmraid.$devenc ] && exit 0

>/tmp/dmraid.$devenc

DM_RAIDS=$(getargs rd.dm.uuid -d rd_DM_UUID=)

if [ -n "$DM_RAIDS" ] || getargbool 0 rd.auto; then

    DM_CLEANUP="no"

    # run dmraid if udev has settled
    info "Scanning for dmraid devices $DM_RAIDS"
    SETS=$(dmraid -c -s)

    if [ "$SETS" = "no raid disks" -o "$SETS" = "no raid sets" ]; then
        return
    fi

    info "Found dmraid sets:"
    echo $SETS|vinfo

    if [ -n "$DM_RAIDS" ]; then
    # only activate specified DM RAIDS
        for r in $DM_RAIDS; do
            for s in $SETS; do
                if [ "${s##$r}" != "$s" ]; then
                    info "Activating $s"
                    dmraid -ay -i -p --rm_partitions "$s" 2>&1 | vinfo
                    [ -e "/dev/mapper/$s" ] && kpartx -a "/dev/mapper/$s" 2>&1 | vinfo
                    udevsettle
                fi
            done
        done
    else
    # scan and activate all DM RAIDS
        for s in $SETS; do
            info "Activating $s"
            dmraid -ay -i -p --rm_partitions "$s" 2>&1 | vinfo
            [ -e "/dev/mapper/$s" ] && kpartx -a "/dev/mapper/$s" 2>&1 | vinfo
        done
    fi

    need_shutdown

fi
