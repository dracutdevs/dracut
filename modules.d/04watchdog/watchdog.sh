#!/bin/sh
if [ -e /dev/watchdog ]; then
	>/dev/watchdog
else
	modprobe ib700wdt
fi
