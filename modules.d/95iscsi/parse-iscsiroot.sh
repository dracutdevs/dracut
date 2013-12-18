#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Preferred format:
#       root=iscsi:[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
#       [root=*] netroot=iscsi:[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
#
# Legacy formats:
#       [net]root=[iscsi] iscsiroot=[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
#       [net]root=[iscsi] iscsi_firmware
#
# root= takes precedence over netroot= if root=iscsi[...]
#

# This script is sourced, so root should be set. But let's be paranoid
[ -z "$root" ] && root=$(getarg root=)
if [ -z "$netroot" ]; then
    for netroot in $(getargs netroot=); do
        [ "${netroot%%:*}" = "iscsi" ] && break
    done
    [ "${netroot%%:*}" = "iscsi" ] || unset netroot
fi
[ -z "$iscsiroot" ] && iscsiroot=$(getarg iscsiroot=)
[ -z "$iscsi_firmware" ] && getargbool 0 rd.iscsi.firmware -y iscsi_firmware && iscsi_firmware="1"

[ -n "$iscsiroot" ] && [ -n "$iscsi_firmware" ] && die "Mixing iscsiroot and iscsi_firmware is dangerous"

type write_fs_tab >/dev/null 2>&1 || . /lib/fs-lib.sh

# Root takes precedence over netroot
if [ "${root%%:*}" = "iscsi" ] ; then
    if [ -n "$netroot" ] ; then
        echo "Warning: root takes precedence over netroot. Ignoring netroot"
    fi
    netroot=$root
    # if root is not specified try to mount the whole iSCSI LUN
    printf 'ENV{DEVTYPE}!="partition", SYMLINK=="disk/by-path/*-iscsi-*-*", SYMLINK+="root"\n' >> /etc/udev/rules.d/99-iscsi-root.rules
    root=/dev/root

    write_fs_tab /dev/root
fi

# If it's not empty or iscsi we don't continue
[ -z "$netroot" ] || [ "${netroot%%:*}" = "iscsi" ] || return

if [ -n "$iscsiroot" ] ; then
    [ -z "$netroot" ]  && netroot=$root

    # @deprecated
    echo "Warning: Argument iscsiroot is deprecated and might be removed in a future"
    echo "release. See 'man dracut.kernel' for more information."

    # Accept iscsiroot argument?
    [ -z "$netroot" ] || [ "$netroot" = "iscsi" ] || \
        die "Argument iscsiroot only accepted for empty root= or [net]root=iscsi"

    # Override root with iscsiroot content?
    [ -z "$netroot" ] || [ "$netroot" = "iscsi" ] && netroot=iscsi:$iscsiroot
fi

# iscsi_firmware does not need argument checking
if [ -n "$iscsi_firmware" ] ; then
    netroot=${netroot:-iscsi}
    modprobe -q iscsi_boot_sysfs 2>/dev/null
    modprobe -q iscsi_ibft
    initqueue --onetime --settled /sbin/iscsiroot dummy "$netroot" "$NEWROOT"
fi

# If it's not iscsi we don't continue
[ "${netroot%%:*}" = "iscsi" ] || return

modprobe -q qla4xxx
modprobe -q cxgb3i
modprobe -q cxgb4i
modprobe -q bnx2i
modprobe -q be2iscsi

if [ -z "$iscsi_firmware" ] ; then
    type parse_iscsi_root >/dev/null 2>&1 || . /lib/net-lib.sh
    parse_iscsi_root "$netroot" || return
fi

# ISCSI actually supported?
if ! [ -e /sys/module/iscsi_tcp ]; then
    modprobe -q iscsi_tcp || die "iscsiroot requested but kernel/initrd does not support iscsi"
fi

if [ -n "$netroot" ] && [ "$root" != "/dev/root" ] && [ "$root" != "dhcp" ]; then
    if ! getargbool 1 rd.neednet >/dev/null || ! getarg "ip="; then
        initqueue --onetime --settled /sbin/iscsiroot dummy "$netroot" "$NEWROOT"
    fi
fi

netroot_enc=$(str_replace "$netroot" '/' '\2f')
echo "[ -f '/tmp/iscsistarted-$netroot_enc' ]" > $hookdir/initqueue/finished/iscsi_started.sh

# Done, all good!
rootok=1

# Shut up init error check
[ -z "$root" ] && root="iscsi"
