#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# Just cleans up a previously started syslogd

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

if [ -f /tmp/syslog.server ]; then
    read syslogtype < /tmp/syslog.type
    if command -v "${syslogtype}-stop" >/dev/null; then
        ${syslogtype}-stop
    else
        warn "syslog-cleanup: Could not find script to stop syslog of type \"$syslogtype\". Syslog will not be stopped."
    fi
fi