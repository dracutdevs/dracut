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

adjust_dependencies() {
  sed -i -e \
'/^\[Unit\]/aDefaultDependencies=no\
Conflicts=shutdown.target\
Before=shutdown.target' \
    "$initdir"${1}

}

install() {

  inst_multiple \
    $systemdsystemunitdir/dbus.service \
    $systemdsystemunitdir/dbus.socket \
    /usr/bin/dbus-send \
    /usr/bin/busctl
  adjust_dependencies $systemdsystemunitdir/dbus.service

  if [[ -e /usr/bin/dbus-daemon ]]; then
    inst_multiple \
      /usr/bin/dbus-daemon
  fi

  if [[ -e /usr/bin/dbus-broker ]]; then
    inst_multiple \
      $systemdsystemunitdir/dbus-broker.service \
      /usr/bin/dbus-broker \
      /usr/bin/dbus-broker-launch
    adjust_dependencies $systemdsystemunitdir/dbus-broker.service
  fi

  inst_dir      /etc/dbus-1/system.d
  inst_dir      /usr/share/dbus-1/services
  inst_dir      /usr/share/dbus-1/system-services
  inst_multiple /etc/dbus-1/system.conf
  inst_multiple /usr/share/dbus-1/system.conf \
                /usr/share/dbus-1/services/org.freedesktop.systemd1.service
  inst_multiple $(find /var/lib/dbus)

  grep '^\(d\|message\)bus:' /etc/passwd >> "$initdir/etc/passwd"
  grep '^\(d\|message\)bus:' /etc/group >> "$initdir/etc/group"

  sed -i -e \
'/^\[Unit\]/aDefaultDependencies=no\
Conflicts=shutdown.target\
Before=shutdown.target
/^\[Socket\]/aRemoveOnStop=yes' \
    "$initdir"/usr/lib/systemd/system/dbus.socket

  #We need to make sure that systemd-tmpfiles-setup.service->dbus.socket will not wait local-fs.target to start,
  #If swap is encrypted, this would make dbus wait the timeout for the swap before loading. This could delay sysinit
  #services that are dependent on dbus.service.
  sed -i -Ee \
    '/^After/s/(After[[:space:]]*=.*)(local-fs.target[[:space:]]*)(.*)/\1-\.mount \3/' \
    "$initdir"/usr/lib/systemd/system/systemd-tmpfiles-setup.service
}
