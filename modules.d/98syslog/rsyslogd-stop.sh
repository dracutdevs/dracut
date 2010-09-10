#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# Kills rsyslogd

if [ -f /var/run/syslogd.pid ]; then
    read pid < /var/run/syslogd.pid
    kill $pid
    kill -0 $pid && kill -9 $pid
else
    warn "rsyslogd-stop: Could not find a pid for rsyslogd. Won't kill it."
fi