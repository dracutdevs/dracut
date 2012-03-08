#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

for f in /tmp/dhclient.*.pid; do
    [ -e $f ] || continue
    read PID < $f;
    kill $PID >/dev/null 2>&1
done

sleep 0.1

for f in /tmp/dhclient.*.pid; do
    [ -e $f ] || continue
    read PID < $f;
    kill -9 $PID >/dev/null 2>&1
done
