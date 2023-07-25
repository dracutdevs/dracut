#!/bin/bash

znet_base_args="--no-settle --yes --no-root-update --force"

# at this point in time dracut's vinfo() only logs to journal which is hard for
# s390 users to find and access on a line mode console such as 3215 mode
# so use a vinfo alternative that still prints to the console via kmsg
znet_vinfo() {
    while read -r _znet_vinfo_line || [ -n "$_znet_vinfo_line" ]; do
        # Prefix "<30>" represents facility LOG_DAEMON 3 and loglevel INFO 6:
        # (facility << 3) | level.
        echo "<30>dracut: $_znet_vinfo_line" > /dev/kmsg
    done
}

for ccw_arg in $(getargs rd.ccw -d 'rd_CCW=') $(getargs rd.znet -d 'rd_ZNET='); do
    (
        SAVED_IFS="$IFS"
        IFS=","
        # shellcheck disable=SC2086
        set -- $ccw_arg
        IFS="$SAVED_IFS"
        type="$1"
        subchannel1="$2"
        subchannel2="$3"
        subchannel3="$4"
        echo "rd.znet ${ccw_arg} :" | znet_vinfo
        if [ "$#" -lt 3 ]; then
            echo "rd.znet needs at least 3 list items: type,subchannel1,subchannel2" | znet_vinfo
        fi
        if [ "$1" = "qeth" ]; then
            if [ "$#" -lt 4 ]; then
                echo "rd.znet for type qeth needs at least 4 list items: qeth,subchannel1,subchannel2,subchannel3" | znet_vinfo
            fi
            subchannels="$subchannel1:$subchannel2:$subchannel3"
            shift 4
            # shellcheck disable=SC2086
            chzdev --enable --persistent $znet_base_args \
                "$type" "$subchannels" "$@" 2>&1 | znet_vinfo
        else
            subchannels="$subchannel1:$subchannel2"
            shift 3
            # shellcheck disable=SC2086
            chzdev --enable --persistent $znet_base_args \
                "$type" "$subchannels" "$@" 2>&1 | znet_vinfo
        fi
    )
done

for ifname in $(getargs rd.znet_ifname); do
    IFS=: read -r ifname_if ifname_subchannels _rest <<< "$ifname"
    if [ -z "$ifname_if" ] || [ -z "$ifname_subchannels" ] || [ -n "$_rest" ]; then
        warn "Invalid arguments for rd.znet_ifname="
    else
        {
            ifname_subchannels=${ifname_subchannels//,/|}

            echo 'ACTION!="add|change", GOTO="ccw_ifname_end"'
            echo 'ATTR{type}!="1", GOTO="ccw_ifname_end"'
            echo 'SUBSYSTEM!="net", GOTO="ccw_ifname_end"'
            echo "SUBSYSTEMS==\"ccwgroup\", KERNELS==\"$ifname_subchannels\", DRIVERS==\"?*\" NAME=\"$ifname_if\""
            echo 'LABEL="ccw_ifname_end"'

        } > /etc/udev/rules.d/81-ccw-ifname.rules
    fi
done
