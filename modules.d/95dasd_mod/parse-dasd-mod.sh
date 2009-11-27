#!/bin/sh
[ -d /etc/modprobe.d ] || mkdir /etc/modprobe.d

dasd_arg=$(getarg rd_DASD_MOD=)
if [ -n "$dasd_arg" ]; then
	echo "options dasd_mod dasd=$dasd_arg" >> /etc/modprobe.d/dasd_mod.conf
fi
unset dasd_arg
