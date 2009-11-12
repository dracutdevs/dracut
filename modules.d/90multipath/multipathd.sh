#!/bin/sh

if [ -e /etc/multipath.conf ]; then
	multipathd
fi

