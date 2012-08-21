#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

mount_boot()
{
    boot=$(getarg boot=)

    if [ -n "$boot" ]; then
        case "$boot" in
        LABEL=*)
            boot="$(echo $boot | sed 's,/,\\x2f,g')"
            boot="/dev/disk/by-label/${boot#LABEL=}"
            ;;
        UUID=*)
            boot="/dev/disk/by-uuid/${boot#UUID=}"
            ;;
        /dev/*)
            ;;
        *)
            die "You have to specify boot=<boot device> as a boot option for fips=1" ;;
        esac

        if ! [ -e "$boot" ]; then
            udevadm trigger --action=add >/dev/null 2>&1
            [ -z "$UDEVVERSION" ] && UDEVVERSION=$(udevadm --version)
            i=0
            while ! [ -e $boot ]; do
                if [ $UDEVVERSION -ge 143 ]; then
                    udevadm settle --exit-if-exists=$boot
                else
                    udevadm settle --timeout=30
                fi
                [ -e $boot ] && break
                modprobe scsi_wait_scan && rmmod scsi_wait_scan
                [ -e $boot ] && break
                sleep 0.5
                i=$(($i+1))
                [ $i -gt 40 ] && break
            done
        fi

        [ -e "$boot" ] || return 1

        mkdir /boot
        info "Mounting $boot as /boot"
        mount -oro "$boot" /boot || return 1
    elif [ -d "$NEWROOT/boot" ]; then
        rm -fr /boot
        ln -sf "$NEWROOT/boot" /boot
    fi
}

do_fips()
{
    info "Checking integrity of kernel"
    KERNEL=$(uname -r)

    if ! [ -e "/boot/.vmlinuz-${KERNEL}.hmac" ]; then
        warn "/boot/.vmlinuz-${KERNEL}.hmac does not exist"
        return 1
    fi

    sha512hmac -c "/boot/.vmlinuz-${KERNEL}.hmac" || return 1

    FIPSMODULES=$(cat /etc/fipsmodules)

    info "Loading and integrity checking all crypto modules"
    for module in $FIPSMODULES; do
        if [ "$module" != "tcrypt" ]; then
            modprobe ${module} || return 1
        fi
    done
    info "Self testing crypto algorithms"
    modprobe tcrypt || return 1
    rmmod tcrypt
    info "All initrd crypto checks done"

    > /tmp/fipsdone

    umount /boot >/dev/null 2>&1

    return 0
}
