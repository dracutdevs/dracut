#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

dev="${1:-/dev/root}"

if [ -e "$dev" ]; then
   if strstr "$(udevadm info --query=env \"--name=$dev\")" "ID_FS_TYPE=btrfs"; then
      info "Checking, if btrfs device complete"
      unset __btrfs_mount
      mount -o ro "$dev" /tmp >/dev/null 2>&1
      __btrfs_mount=$?
      [ $__btrfs_mount -eq 0 ] && umount "$dev" >/dev/null 2>&1
      exit $__btrfs_mount
   fi
fi

exit 0
