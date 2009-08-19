#!/bin/sh
# Parses the syslog commandline options
#
#Bootparameters:
#syslogserver=ip    Where to syslog to
#sysloglevel=level  What level has to be logged
#syslogtype=rsyslog|syslog|syslogng  
#                   Don't auto detect syslog but set it
if getarg rdnetdebug ; then
    exec >/tmp/syslog-parse-opts.$1.$$.out
    exec 2>>/tmp/syslog-parse-opts.$1.$$.out
    set -x
fi

syslogserver=$(getarg syslog)
syslogfilters=$(getargs filter)
syslogtype=$(getarg syslogtype)

[ -n "$syslogserver" ] && echo $syslogserver > /tmp/syslog.server
[ -n "$syslogfilters" ] && echo "$syslogfilters" > /tmp/syslog.filters
[ -n "$syslogtype" ] && echo "$syslogtype" > /tmp/syslog.type
