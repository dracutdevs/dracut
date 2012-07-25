#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

getargbool 1 rd.zfcp.conf -d -n rd_NO_ZFCPCONF || rm /etc/zfcp.conf

for zfcp_arg in $(getargs rd.zfcp -d 'rd_ZFCP='); do
    (
        IFS=","
        set $zfcp_arg
        echo "$@" >> /etc/zfcp.conf
    )
done

zfcp_cio_free
