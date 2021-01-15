#!/usr/bin/sh

dcssblk_arg=$(getarg rd.dcssblk=)
if [ $? = 0 ];then
	info "Loading dcssblk segments=$dcssblk_arg"
	modprobe dcssblk segments=$dcssblk_arg
fi
