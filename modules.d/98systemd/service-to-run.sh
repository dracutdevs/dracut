#!/bin/sh
mkdir -p /run/systemd/system/
cp -d -t /run/systemd/system/ /etc/systemd/system/* 2>/dev/null
exit 0

