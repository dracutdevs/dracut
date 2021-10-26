#!/bin/sh
#
# Wrapper used to set environment variables in mdadm environment
#

. /lib/dracut-lib.sh

for envvar in $(getargs rd.md.env=); do
    splitsep '=' "$envvar" key value
    eval export "$key='${value}'"
done
exec /sbin/mdadm.real "${@:-}"
