#!/bin/bash

# called by dracut
check() {
  require_binaries dbus-daemon || return 1
  
  return 255
}

depends() {
  echo systemd
  return 0
}

install() {
  inst_multiple \
    /usr/lib/systemd/system/dbus.service \
    /usr/lib/systemd/system/dbus.socket \
    /usr/bin/dbus-daemon \
    /usr/bin/dbus-send

  inst_multiple $(find /usr/share/dbus-1)
  inst_multiple $(find /etc/dbus-1)
  inst_multiple $(find /var/lib/dbus)

  grep '^dbus:' /etc/passwd >> "$initdir/etc/passwd"
  grep '^dbus:' /etc/group >> "$initdir/etc/group"

  sed -e \
'/^\[Unit\]/aDefaultDependencies=no\
Conflicts=shutdown.target\
Before=shutdown.target
/^\[Socket\]/aRemoveOnStop=yes' \
    /usr/lib/systemd/system/dbus.service > \
    "$initdir"/usr/lib/systemd/system/dbus.service

  sed -e \
'/^\[Unit\]/aDefaultDependencies=no\
Conflicts=shutdown.target\
Before=shutdown.target
/^\[Socket\]/aRemoveOnStop=yes' \
    /usr/lib/systemd/system/dbus.socket > \
    "$initdir"/usr/lib/systemd/system/dbus.socket
}
