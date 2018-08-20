#!/bin/sh

strstr "$(cat /proc/misc)" device-mapper || modprobe dm-mod
modprobe dm-mirror 2>/dev/null
