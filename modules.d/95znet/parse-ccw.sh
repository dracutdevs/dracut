#!/bin/sh

for ccw_arg in $(getargs rd.ccw -d 'rd_CCW=') $(getargs rd.znet -d 'rd_ZNET='); do
    echo $ccw_arg >> /etc/ccw.conf
done

for ifname in $(getargs rd.znet_ifname); do
    IFS=: read ifname_if ifname_subchannels _rest <<< "$ifname"
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

znet_cio_free
