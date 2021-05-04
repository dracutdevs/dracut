#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

getarg "rd.cmdline=ask" || exit 0

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
while read -r -p "> " ${BASH:+-e} line || [ -n "$line" ]; do
    [ "$line" = "." ] && break
    [ -n "$line" ] && printf -- "%s\n" "$line" >> /etc/cmdline.d/99-cmdline-ask.conf
done

exit 0
