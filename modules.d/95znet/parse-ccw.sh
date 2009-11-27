#!/bin/sh
for ccw_arg in $(getargs 'rd_CCW='); do
    echo $ccw_arg >> /etc/ccw.conf
done

