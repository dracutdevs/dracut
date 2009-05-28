#!/bin/sh

for f in /tmp/dhclient.*.pid; do
    [ "$f" != "/tmp/dhclient.*.pid" ] && kill $(cat $f)
done
