#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

sleep 0.5
echo
sleep 0.5
echo
sleep 0.5
echo
echo
echo
echo
echo "Enter additional kernel command line parameter (end with ctrl-d or .)"
while read -e -p "> " line; do
    [[ "$line" == "." ]] && break
    [[ "$line" ]] && printf -- "%s\n" "$line" >> /etc/cmdline.d/99-cmdline-ask.conf
done

exit 0
