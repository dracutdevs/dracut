#!/bin/sh

type vwarn > /dev/null 2>&1 || . /lib/dracut-lib.sh

# Symlinking /usr/bin/ntfs-3g as /sbin/mount.ntfs seems to boot
# at the first glance, but ends with lots and lots of squashfs
# errors, because systemd attempts to kill the ntfs-3g process?!
# See https://systemd.io/ROOT_STORAGE_DAEMONS/
if [ -x "/usr/bin/ntfs-3g" ]; then
    (
        ln -s /usr/bin/ntfs-3g /run/@ntfs-3g
        (sleep 1 && rm /run/@ntfs-3g) &
        # shellcheck disable=SC2123
        PATH=/run
        exec @ntfs-3g "$@"
    ) | vwarn
else
    die "Failed to mount block device of live image: Missing NTFS support"
    exit 1
fi
