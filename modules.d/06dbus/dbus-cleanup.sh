#!/bin/sh
systemctl stop dbus.service dbus.socket
rm -rf /run/dbus
