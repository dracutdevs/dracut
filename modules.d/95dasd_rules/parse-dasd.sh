#!/bin/bash

allow_device() {
    local ccw=$1

    if [ -x /sbin/cio_ignore ] && cio_ignore -i "$ccw" > /dev/null; then
        cio_ignore -r "$ccw"
    fi
}

if [[ -f /sys/firmware/ipl/ipl_type ]] && [[ $(< /sys/firmware/ipl/ipl_type) == "ccw" ]]; then
    allow_device "$(< /sys/firmware/ipl/device)"
fi

for dasd_arg in $(getargs root=) $(getargs resume=); do
    [[ $dasd_arg =~ /dev/disk/by-path/ccw-* ]] || continue

    ccw_dev="${dasd_arg##*/ccw-}"
    allow_device "${ccw_dev%%-*}"
done

for dasd_arg in $(getargs rd.dasd=); do
    IFS=',' read -r -a devs <<< "$dasd_arg"
    declare -p devs
    for dev in "${devs[@]}"; do
        case "$dev" in
            autodetect | probeonly) ;;

            *-*)
                IFS="-" read -r start end _ <<< "${dev%(ro)}"
                prefix=${start%.*}
                start=${start##*.}
                for rdev in $(seq $((16#$start)) $((16#$end))); do
                    allow_device "$(printf "%s.%04x" "$prefix" "$rdev")"
                done
                ;;
            *)
                IFS="." read -r sid ssid chan _ <<< "${dev%(ro)}"
                allow_device "$(printf "%01x.%01x.%04x" $((16#$sid)) $((16#$ssid)) $((16#$chan)))"
                ;;
        esac
    done
done
