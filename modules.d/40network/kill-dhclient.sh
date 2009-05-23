#!/bin/sh

for f in /dhclient.*.pid; do
    [ "$f" != "/dhclient.*.pid" ] && kill $(cat $f)
done
