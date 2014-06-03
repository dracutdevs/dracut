#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# Huh? Empty $1?
[ -z "$1" ] && exit 1

# Huh? Empty $2?
[ -z "$2" ] && exit 1

# Huh? Empty $3?
[ -z "$3" ] && exit 1

# root is in the form root=nbd:srv:port[:fstype[:rootflags[:nbdopts]]]
netif="$1"
nroot="$2"
NEWROOT="$3"

# If it's not nbd we don't continue
[ "${nroot%%:*}" = "nbd" ] || return

nroot=${nroot#nbd:}
nbdserver=${nroot%%:*}; nroot=${nroot#*:}
nbdport=${nroot%%:*}; nroot=${nroot#*:}
nbdfstype=${nroot%%:*}; nroot=${nroot#*:}
nbdflags=${nroot%%:*}
nbdopts=${nroot#*:}

# If nbdport not an integer, then assume name based import
if [ ! -z $(echo "$nbdport" | sed 's/[0-9]//g') ]; then
    nbdport="-N $nbdport"
fi

if [ "$nbdopts" = "$nbdflags" ]; then
    unset nbdopts
fi
if [ "$nbdflags" = "$nbdfstype" ]; then
    unset nbdflags
fi
if [ "$nbdfstype" = "$nbdport" ]; then
    unset nbdfstype
fi
if [ -z "$nbdfstype" ]; then
    nbdfstype=auto
fi

# look through the NBD options and pull out the ones that need to
# go before the host etc. Append a ',' so we know we terminate the loop
nbdopts=${nbdopts},
while [ -n "$nbdopts" ]; do
    f=${nbdopts%%,*}
    nbdopts=${nbdopts#*,}
    if [ -z "$f" ]; then
        break
    fi
    if [ -z "${f%bs=*}" -o -z "${f%timeout=*}" ]; then
        preopts="$preopts $f"
        continue
    fi
    opts="$opts $f"
done

# look through the flags and see if any are overridden by the command line
nbdflags=${nbdflags},
while [ -n "$nbdflags" ]; do
    f=${nbdflags%%,*}
    nbdflags=${nbdflags#*,}
    if [ -z "$f" ]; then
        break
    fi
    if [ "$f" = "ro" -o "$f" = "rw" ]; then
        nbdrw=$f
        continue
    fi
    fsopts=${fsopts:+$fsopts,}$f
done

getarg ro && nbdrw=ro
getarg rw && nbdrw=rw
fsopts=${fsopts:+$fsopts,}${nbdrw}

# XXX better way to wait for the device to be made?
i=0
while [ ! -b /dev/nbd0 ]; do
    [ $i -ge 20 ] && exit 1
    if [ $UDEVVERSION -ge 143 ]; then
        udevadm settle --exit-if-exists=/dev/nbd0
    else
        sleep 0.1
    fi
    i=$(($i + 1))
done

# If we didn't get a root= on the command line, then we need to
# add the udev rules for mounting the nbd0 device
if [ "$root" = "block:/dev/root" -o "$root" = "dhcp" ]; then
    printf 'KERNEL=="nbd0", ENV{DEVTYPE}!="partition", ENV{ID_FS_TYPE}=="?*", SYMLINK+="root"\n' >> /etc/udev/rules.d/99-nbd-root.rules
    udevadm control --reload
    type write_fs_tab >/dev/null 2>&1 || . /lib/fs-lib.sh
    write_fs_tab /dev/root "$nbdfstype" "$fsopts"
    wait_for_dev -n /dev/root

    if [ -z "$DRACUT_SYSTEMD" ]; then
        printf '/bin/mount %s\n' \
             "$NEWROOT" \
             > $hookdir/mount/01-$$-nbd.sh
    fi
fi

if strstr "$(nbd-client --help 2>&1)" "systemd-mark"; then
    preopts="--systemd-mark $preopts"
fi

nbd-client $preopts "$nbdserver" $nbdport /dev/nbd0 $opts || exit 1

# NBD doesn't emit uevents when it gets connected, so kick it
echo change > /sys/block/nbd0/uevent
udevadm settle
need_shutdown
exit 0
