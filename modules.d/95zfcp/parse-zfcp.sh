#!/bin/sh
getarg rd_NO_ZFCPCONF && rm /etc/zfcp.conf

for zfcp_arg in $(getargs 'rd_ZFCP='); do
    ( 
        IFS=","
        set $zfcp_arg
        echo "$@" >> /etc/zfcp.conf
    )
done

zfcp_cio_free
