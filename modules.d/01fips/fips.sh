#!/bin/sh

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
        PARTUUID=*)
            boot="/dev/disk/by-partuuid/${boot#PARTUUID=}"
            ;;
        PARTLABEL=*)
            boot="/dev/disk/by-partlabel/${boot#PARTLABEL=}"
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
        rm -fr -- /boot
        ln -sf "$NEWROOT/boot" /boot
    fi
}

do_rhevh_check()
{
    KERNEL=$(uname -r)
    kpath=${1}

    # If we're on RHEV-H, the kernel is in /run/initramfs/live/vmlinuz0
    HMAC_SUM_ORIG=$(cat $NEWROOT/boot/.vmlinuz-${KERNEL}.hmac | while read a b || [ -n "$a" ]; do printf "%s\n" $a; done)
    HMAC_SUM_CALC=$(sha512hmac $kpath | while read a b || [ -n "$a" ]; do printf "%s\n" $a; done || return 1)
    if [ -z "$HMAC_SUM_ORIG" ] || [ -z "$HMAC_SUM_CALC" ] || [ "${HMAC_SUM_ORIG}" != "${HMAC_SUM_CALC}" ]; then
        warn "HMAC sum mismatch"
        return 1
    fi
    info "rhevh_check OK"
    return 0
}

do_fips()
{
    local _v
    local _s
    local _v
    local _module

    KERNEL=$(uname -r)

    FIPSMODULES=$(cat /etc/fipsmodules)

    info "Loading and integrity checking all crypto modules"
    mv /etc/modprobe.d/fips.conf /etc/modprobe.d/fips.conf.bak
    for _module in $FIPSMODULES; do
        if [ "$_module" != "tcrypt" ]; then
            if ! modprobe "${_module}"; then
                # check if kernel provides generic algo
                _found=0
                while read _k _s _v || [ -n "$_k" ]; do
                    [ "$_k" != "name" -a "$_k" != "driver" ] && continue
                    [ "$_v" != "$_module" ] && continue
                    _found=1
                    break
                done </proc/crypto
                [ "$_found" = "0" ] && return 1
            fi
        fi
    done
    mv /etc/modprobe.d/fips.conf.bak /etc/modprobe.d/fips.conf

    info "Self testing crypto algorithms"
    modprobe tcrypt || return 1
    rmmod tcrypt

    info "Checking integrity of kernel"
    if [ -e "/run/initramfs/live/vmlinuz0" ]; then
        do_rhevh_check /run/initramfs/live/vmlinuz0 || return 1
    elif [ -e "/run/initramfs/live/isolinux/vmlinuz0" ]; then
        do_rhevh_check /run/initramfs/live/isolinux/vmlinuz0 || return 1
    else
        BOOT_IMAGE="$(getarg BOOT_IMAGE)"
        [ -e "/boot/.${BOOT_IMAGE}.hmac" ] || BOOT_IMAGE="vmlinuz-${KERNEL}"

        if ! [ -e "/boot/.${BOOT_IMAGE}.hmac" ]; then
            warn "/boot/.${BOOT_IMAGE}.hmac does not exist"
            return 1
        fi
        sha512hmac -c "/boot/.${BOOT_IMAGE}.hmac" || return 1
    fi

    info "All initrd crypto checks done"

    > /tmp/fipsdone

    umount /boot >/dev/null 2>&1

    return 0
}
