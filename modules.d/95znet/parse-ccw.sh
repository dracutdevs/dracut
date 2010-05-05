#!/bin/sh
for ccw_arg in $(getargs 'rd_CCW=') $(getargs 'rd_ZNET='); do
    echo $ccw_arg >> /etc/ccw.conf
done

znet_cio_free
