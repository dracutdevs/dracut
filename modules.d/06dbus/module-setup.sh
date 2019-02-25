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
  local DBUS_SERVICE=/usr/lib/systemd/system/dbus.service
  if [[ -e $DBUS_SERVICE ]]; then
    if [[ -L $DBUS_SERVICE ]]; then
      DBUS_SERVICE=$(readlink $DBUS_SERVICE)
    fi
  else
    DBUS_SERVICE=/etc/systemd/system/dbus.service
    if [[ -e $DBUS_SERVICE ]]; then
      if [[ -L $DBUS_SERVICE ]]; then
        DBUS_SERVICE=$(readlink $DBUS_SERVICE)
      fi
    else
      echo "Could not find dbus.service";
      exit 1
    fi
  fi

  inst_multiple \
    $DBUS_SERVICE \
    /usr/lib/systemd/system/dbus.socket \
    /usr/bin/dbus-daemon \
    /usr/bin/dbus-send

  inst_multiple $(find /usr/share/dbus-1)
  inst_multiple $(find /etc/dbus-1)
  inst_multiple $(find /var/lib/dbus)

  grep '^dbus:' /etc/passwd >> "$initdir/etc/passwd"
  grep '^dbus:' /etc/group >> "$initdir/etc/group"

  systemctl --root "$initdir" enable $DBUS_SERVICE > /dev/null 2>&1

  sed -i -e \
'/^\[Unit\]/aDefaultDependencies=no\
Conflicts=shutdown.target\
Before=shutdown.target
/^\[Socket\]/aRemoveOnStop=yes' \
    "$initdir"$DBUS_SERVICE

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
