#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
do_fips()
{
    FIPSMODULES=$(cat /etc/fipsmodules)
    BOOT=$(getarg boot=)
    KERNEL=$(uname -r)
    udevadm trigger --action=add >/dev/null 2>&1
    case "$boot" in
        block:LABEL=*|LABEL=*)
            boot="${boot#block:}"
            boot="$(echo $boot | sed 's,/,\\x2f,g')"
            boot="/dev/disk/by-label/${boot#LABEL=}"
            bootok=1 ;;
        block:UUID=*|UUID=*)
            boot="${boot#block:}"
            boot="/dev/disk/by-uuid/${root#UUID=}"
            bootok=1 ;;
        /dev/*)
            bootok=1 ;;
    esac

    [ -z "$UDEVVERSION" ] && UDEVVERSION=$(udevadm --version)
    
    if [ $UDEVVERSION -ge 143 ]; then
        udevadm settle --exit-if-exists=$boot
    else
        udevadm settle --timeout=30
    fi

    [ -e "$boot" ]

    mkdir /boot
    info "Mounting $boot as /boot"
    mount -oro "$boot" /boot

    info "Checking integrity of kernel"

    if ! [ -e "/boot/.vmlinuz-${KERNEL}.hmac" ]; then
        warn "/boot/.vmlinuz-${KERNEL}.hmac does not exist"
        return 1
    fi

    sha512hmac -c "/boot/.vmlinuz-${KERNEL}.hmac" || return 1

    info "Umounting /boot"
    umount /boot

    info "Loading and integrity checking all crypto modules"
    for module in $FIPSMODULES; do
        if [ "$module" != "tcrypt" ]; then
            modprobe ${module} || return 1
        fi
    done
    info "Self testing crypto algorithms"
    modprobe tcrypt noexit=1 || return 1
    rmmod tcrypt
    info "All initrd crypto checks done"  

    return 0
}

if ! fipsmode=$(getarg fips) || [ $fipsmode == "0" ]; then
    rm -f /etc/modprobe.d/fips.conf >/dev/null 2>&1
else
    set -e
    do_fips || die "FIPS integrity test failed"
    set +e
fi
