#!/bin/sh
[ -c /dev/watchdog ] && echo -n 'V' > /dev/watchdog
