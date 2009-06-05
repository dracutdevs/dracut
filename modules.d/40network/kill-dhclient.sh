#!/bin/sh

for f in /tmp/dhclient.*.pid; do
    [ -e $f ] || continue
    read PID < $f;
    kill $PID;
done
