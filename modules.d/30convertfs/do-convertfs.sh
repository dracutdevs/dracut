#!/bin/sh

if getargbool 0 rd.convertfs; then
    if getargbool 0 rd.debug; then
        sh -x convertfs "$NEWROOT"
    else
        convertfs "$NEWROOT"
    fi 2>&1 | vinfo
fi
