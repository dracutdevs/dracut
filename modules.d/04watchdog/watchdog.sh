#!/bin/sh
if [ -e /dev/watchdog ]; then
	info "Triggering watchdog"
	>/dev/watchdog
else
	modprobe ib700wdt
fi
