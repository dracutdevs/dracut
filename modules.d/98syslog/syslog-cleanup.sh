#!/bin/sh
# Just cleans up a previously started syslogd
. /lib/dracut-lib.sh


if getarg rdnetdebug ; then
    exec >/tmp/syslog-cleanup.$1.$$.out
    exec 2>>/tmp/syslog-cleanup.$1.$$.out
    set -x
fi

if [ -f /tmp/syslog.server ]; then
	read syslogtype < /tmp/syslog.type
	if [ -e "/sbin/${syslogtype}-stop" ]; then
		${syslogtype}-stop
	else
		warn "syslog-cleanup: Could not find script to stop syslog of type \"$syslogtype\". Syslog will not be stopped."
	fi
fi