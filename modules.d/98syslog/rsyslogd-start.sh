#!/bin/sh
# Triggered by udev and starts rsyslogd with bootparameters
. /lib/dracut-lib.sh

if getarg rdnetdebug ; then
    exec >/tmp/rsyslogd-start.$1.$$.out
    exec 2>>/tmp/rsyslogd-start.$1.$$.out
    set -x
fi

rsyslog_config() {
	local server=$1
	shift
	local syslog_template=$1
	shift
    local filters=$*
    local filter=
    
    cat $syslog_template

	for filter in $filters; do
	   echo "${filter} @${server}"
    done
#	echo "*.* /tmp/syslog"
}

read server < /tmp/syslog.server
read filters < /tmp/syslog.filter
[ -z "$filters" ] && filters="kern.*"
read conf < /tmp/syslog.conf
[ -z "$conf" ] && conf="/etc/rsyslog.conf" && echo "$conf" > /tmp/syslog.conf

template=/etc/templates/rsyslog.conf
if [ -n "$server" ]; then
   rsyslog_config "$server" "$template" "$filters" > $conf
   /sbin/rsyslogd -c3
fi 