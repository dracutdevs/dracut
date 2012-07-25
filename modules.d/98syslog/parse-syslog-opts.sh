#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# Parses the syslog commandline options
#
#Bootparameters:
#syslogserver=ip    Where to syslog to
#sysloglevel=level  What level has to be logged
#syslogtype=rsyslog|syslog|syslogng
#                   Don't auto detect syslog but set it
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

syslogserver=$(getarg syslog.server -d syslog)
syslogfilters=$(getargs syslog.filter -d filter)
syslogtype=$(getarg syslog.type -d syslogtype)

[ -n "$syslogserver" ] && echo $syslogserver > /tmp/syslog.server
[ -n "$syslogfilters" ] && echo "$syslogfilters" > /tmp/syslog.filters
[ -n "$syslogtype" ] && echo "$syslogtype" > /tmp/syslog.type
