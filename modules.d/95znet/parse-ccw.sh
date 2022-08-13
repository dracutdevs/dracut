#!/bin/sh

for ccw_arg in $(getargs rd.ccw -d 'rd_CCW=') $(getargs rd.znet -d 'rd_ZNET='); do
    echo "$ccw_arg" >> /etc/ccw.conf
done

getargs rd.znet_ifname | while IFS=: read -r ifname_if ifname_subchannels _rest; do
    if [ -z "$ifname_if" ] || [ -z "$ifname_subchannels" ] || [ -n "$_rest" ]; then
        warn "Invalid arguments for rd.znet_ifname="
    else
        {
            echo 'ACTION!="add|change", GOTO="ccw_ifname_end"'
            echo 'ATTR{type}!="1", GOTO="ccw_ifname_end"'
            echo 'SUBSYSTEM!="net", GOTO="ccw_ifname_end"'
            echo "SUBSYSTEMS==\"ccwgroup\", KERNELS==\"$(echo "$ifname_subchannels" | tr , \|)\", DRIVERS==\"?*\" NAME=\"$ifname_if\""
            echo 'LABEL="ccw_ifname_end"'
        } > /etc/udev/rules.d/81-ccw-ifname.rules
    fi
done

znet_cio_free
