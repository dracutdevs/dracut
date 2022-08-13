#!/bin/sh
# Accepted formats:
# 	rootfstype=virtiofs root=<tag>
# 	root=virtiofs:<tag>

if [ "${fstype}" = "virtiofs" ] || [ "${root%%:*}" = "virtiofs" ]; then
    # shellcheck disable=SC2034
    rootok=1
fi
