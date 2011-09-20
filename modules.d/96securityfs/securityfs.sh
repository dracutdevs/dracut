#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

SECURITYFSDIR="/sys/kernel/security"
export SECURITYFSDIR

if ! ismounted "${SECURITYFSDIR}"; then
   mount -t securityfs -o nosuid,noexec,nodev securityfs ${SECURITYFSDIR} >/dev/null 2>&1
fi
