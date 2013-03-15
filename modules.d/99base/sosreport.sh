#!/bin/sh

echo 'Generating "/run/initramfs/sosreport.txt"'

exec >/run/initramfs/sosreport.txt 2>&1

set -x

cat /proc/self/mountinfo
cat /proc/mounts

blkid
blkid -o udev

ls -l /dev/disk/by*

cat /proc/cmdline

[ -f /etc/cmdline ] && cat /etc/cmdline

for _i in /etc/cmdline.d/*.conf; do
    [ -f "$_i" ] || break
    echo $_i
    cat $_i
done

for _i in /etc/conf.d/*.conf; do
    [ -f "$_i" ] || break
    echo $_i
    cat $_i
done

if command -v lvm >/dev/null 2>/dev/null; then
    lvm pvdisplay
    lvm vgdisplay
    lvm lvdisplay
fi

command -v dmsetup >/dev/null 2>/dev/null && dmsetup ls --tree

cat /proc/mdstat

if command -v journalctl >/dev/null 2>/dev/null; then
    journalctl -ab --no-pager -o short-monotonic
else
    dmesg
    [ -f /run/initramfs/init.log ] && cat /run/initramfs/init.log
fi

