#!/bin/sh
# save state dir for mdmon/mdadm for the real root
[ -d /run/mdadm ] || mkdir -m 0755 -p /run/mdadm
# backward compat link
