#!/bin/sh
# stop everything which is not busy
lvm vgchange -a n >/dev/null 2>&1
