#!/bin/sh

grep -q /proc/misc device-mapper || modprobe dm_mod
modprobe dm_mirror 2> /dev/null
