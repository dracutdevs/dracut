#!/bin/sh
# convert openSUSE / SLE initrd command lines into dracut ones
# linuxrc=trace shell=1 sysrq=yes sysrq=1-9 journaldev mduuid
# TargetAddress TargetPort TargetName

# sysrq
sysrq=$(getarg sysrq)
if [ "$sysrq" ] && [ "$sysrq" != "no" ]; then
    echo 1 > /proc/sys/kernel/sysrq
    case "$sysrq" in
        0|1|2|3|4|5|6|7|8|9)
            echo $sysrq > /proc/sysrq-trigger
            ;;
    esac
fi

# debug
if getarg linuxrc=trace; then
    echo "rd.debug rd.udev.debug" >> /etc/cmdline.d/99-suse.conf
    unset CMDLINE
fi

# debug shell
if getargbool 0 shell; then
    echo "rd.break" >> /etc/cmdline.d/99-suse.conf
    unset CMDLINE
fi

# journaldev
journaldev=$(getarg journaldev)
if [ -n "$journaldev" ]; then
    echo "root.journaldev=$journaldev" >> /etc/cmdline.d/99-suse.conf
    unset CMDLINE
fi

# mduuid
mduuid=$(getarg mduuid)
if [ -n "$mduuid" ]; then
    echo "rd.md.uuid=$mduuid" >> /etc/cmdline.d/99-suse.conf
    unset CMDLINE
fi

# TargetAddress / TargetPort / TargetName
TargetAddress=$(getarg TargetAddress)
TargetPort=$(getarg TargetPort)
TargetName=$(getarg TargetName)

if [ -n "$TargetAddress" -a -n "$TargetName" ]; then
    echo "netroot=iscsi:$TargetAddress::$TargetPort::$TargetName" >> /etc/cmdline.d/99-suse.conf
    unset CMDLINE
fi
