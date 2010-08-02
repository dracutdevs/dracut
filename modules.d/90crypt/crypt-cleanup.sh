#!/bin/sh
# close everything which is not busy
rm -f /etc/udev/rules.d/70-luks.rules >/dev/null 2>&1

while true; do
	local do_break="y"
	for i in /dev/mapper/luks-*; do
	    cryptsetup luksClose $i >/dev/null 2>&1 && do_break=n
	done
	[ "$do_break" = "y" ] && break
done
