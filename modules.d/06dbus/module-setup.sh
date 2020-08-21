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

  dbus_system_services="
        org.freedesktop.systemd1
        org.freedesktop.timedate1
        org.freedesktop.hostname1
  "
  inst_dir      /etc/dbus-1/system.d
  inst_dir      /usr/share/dbus-1/services
  inst_dir      /usr/share/dbus-1/system-services
  inst_multiple /etc/dbus-1/system.conf
  inst_multiple /usr/share/dbus-1/system.conf \
                /usr/share/dbus-1/services/org.freedesktop.systemd1.service
  for service in $dbus_system_services ; do
      inst_multiple        /etc/dbus-1/system.d/${service}.conf \
              /usr/share/dbus-1/system-services/${service}.service
  done
  inst_multiple $(find /var/lib/dbus)

  inst_hook cleanup 99 "$moddir/dbus-cleanup.sh"

  grep '^messagebus:' /etc/passwd >> "$initdir/etc/passwd"
  grep '^messagebus:' /etc/group >> "$initdir/etc/group"

  # do not enable -- this is a static service
  #systemctl --root "$initdir" enable $DBUS_SERVICE > /dev/null 2>&1

  sed -i -e \
'/^\[Unit\]/aDefaultDependencies=no\
Conflicts=shutdown.target\
Before=shutdown.target' \
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
