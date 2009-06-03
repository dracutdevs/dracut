#!/bin/sh

# first trigger graphics subsystem
udevadm trigger --subsystem-match=graphics >/dev/null 2>&1
udevadm settle --timeout=30 >/dev/null 2>&1
/bin/plymouth --show-splash

