#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

for ccw_arg in $(getargs rd.ccw -d 'rd_CCW=') $(getargs rd.znet -d 'rd_ZNET='); do
    echo $ccw_arg >> /etc/ccw.conf
done

znet_cio_free
