#!/bin/sh

for i in /dev/mapper/mpath*; do
    [ -b "$i" ] || continue
    need_shutdown
    break
done
