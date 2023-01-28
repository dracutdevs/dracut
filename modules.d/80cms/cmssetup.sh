#!/bin/bash

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

function dasd_settle() {
    local dasd_status
    dasd_status=$(lszdev dasd "$1" --columns ATTRPATH:status --no-headings --active)
    if [ ! -f "$dasd_status" ]; then
        return 1
    fi
    local i=1
    while [ $i -le 60 ]; do
        local status
        status=$(lszdev dasd "$1" --columns ATTR:status --no-headings --active)
        case $status in
            online | unformatted)
                return 0
                ;;
            *)
                sleep 0.1
                i=$((i + 1))
                ;;
        esac
    done
    return 1
}

# read file from CMS and write it to /tmp
function readcmsfile() { # $1=dasdport $2=filename
    local dev
    local devname
    local ret=0
    if [ $# -ne 2 ]; then return; fi
    # precondition: udevd created block device node

    dev="$1"
    chzdev --enable --active --yes --quiet --no-root-update --force dasd "$dev" || return 1
    if ! dasd_settle "$dev"; then
        echo $"Could not access DASD $dev in time"
        return 1
    fi

    devname=$(lszdev dasd "$dev" --columns NAMES --no-headings --active)
    [[ -n $devname ]] || return 1

    [[ -d /mnt ]] || mkdir -p /mnt
    if cmsfs-fuse --to=UTF-8 -a /dev/"$devname" /mnt; then
        cat /mnt/"$2" > /run/initramfs/"$2"
        umount /mnt || umount -l /mnt
        udevadm settle
    else
        echo $"Could not read conf file $2 on CMS DASD $1."
        ret=1
    fi

    chzdev --disable --active --yes --quiet --no-root-update --force dasd "$dev"

    # unbind all dasds to unload the dasd modules for a clean start
    (
        cd /sys/bus/ccw/drivers/dasd-eckd || exit
        for i in *.*; do echo "$i" > unbind 2> /dev/null; done
    )
    (
        cd /sys/bus/ccw/drivers/dasd-fba || exit
        for i in *.*; do echo "$i" > unbind 2> /dev/null; done
    )
    udevadm settle
    modprobe -r dasd_eckd_mod
    udevadm settle
    modprobe -r dasd_fba_mod
    udevadm settle
    modprobe -r dasd_diag_mod
    udevadm settle
    modprobe -r dasd_mod
    udevadm settle
    return $ret
}

processcmsfile() {
    source /tmp/cms.conf
    SUBCHANNELS="$(echo "$SUBCHANNELS" | sed 'y/ABCDEF/abcdef/')"

    if [[ $NETTYPE ]]; then
        (
            echo -n "$NETTYPE","$SUBCHANNELS"
            [[ $PORTNAME ]] && echo -n ",portname=$PORTNAME"
            [[ $LAYER2 ]] && echo -n ",layer2=$LAYER2"
            [[ $NETTYPE == "ctc" ]] && [[ $CTCPROT ]] && echo -n ",protocol=$CTCPROT"
            echo
        ) >> /etc/ccw.conf

        OLDIFS=$IFS
        IFS=,
        read -r -a subch_array <<< "indexzero,$SUBCHANNELS"
        IFS=$OLDIFS
        devbusid=${subch_array[1]}
        if [ "$NETTYPE" = "ctc" ]; then
            driver="ctcm"
        else
            driver=$NETTYPE
        fi

        # shellcheck disable=SC2016
        printf 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="%s", KERNELS=="%s", ENV{INTERFACE}=="?*", RUN+="/sbin/initqueue --onetime --unique --name cmsifup-$name /sbin/cmsifup $name"\n' "$driver" "$devbusid" > /etc/udev/rules.d/99-cms.rules
        # remove the default net rules
        rm -f -- /etc/udev/rules.d/91-default-net.rules
        # shellcheck disable=SC2016
        [[ -f /etc/udev/rules.d/90-net.rules ]] \
            || printf 'SUBSYSTEM=="net", ACTION=="online", RUN+="/sbin/initqueue --onetime --env netif=$name source_hook initqueue/online"\n' >> /etc/udev/rules.d/99-cms.rules
        udevadm control --reload
        znet_cio_free
    fi

    if [[ $DASD ]] && [[ $DASD != "none" ]]; then
        echo "$DASD" | normalize_dasd_arg > /etc/dasd.conf
        echo "options dasd_mod dasd=$DASD" > /etc/modprobe.d/dasd_mod.conf
        dasd_cio_free
    fi

    for i in ${!FCP_*}; do
        echo "${!i}" | while read -r port rest || [ -n "$port" ]; do
            case $port in
                *.*.*) ;;

                *.*)
                    port="0.$port"
                    ;;
                *)
                    port="0.0.$port"
                    ;;
            esac
            # shellcheck disable=SC2086
            set -- $rest
            SAVED_IFS="$IFS"
            IFS=":"
            # Intentionally do not dynamically activate now, but only generate udev
            # rules, which activate the device later during udev coldplug.
            if [[ -z $rest ]]; then
                chzdev --enable --persistent \
                    --no-settle --yes --quiet --no-root-update --force \
                    zfcp-host "$port" 2>&1 | vinfo
            else
                chzdev --enable --persistent \
                    --no-settle --yes --quiet --no-root-update --force \
                    zfcp-lun "$port:$*" 2>&1 | vinfo
            fi
            IFS="$SAVED_IFS"
        done
    done
}

[[ $CMSDASD ]] || CMSDASD=$(getarg "CMSDASD=")
[[ $CMSCONFFILE ]] || CMSCONFFILE=$(getarg "CMSCONFFILE=")

# Parse configuration
if [ -n "$CMSDASD" -a -n "$CMSCONFFILE" ]; then
    if readcmsfile "$CMSDASD" "$CMSCONFFILE"; then
        ln -s /run/initramfs/"$CMSCONFFILE" /tmp/"$CMSCONFFILE"
        ln -s /run/initramfs/"$CMSCONFFILE" /tmp/cms.conf
        processcmsfile
    fi
fi
