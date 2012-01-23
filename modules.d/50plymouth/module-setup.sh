#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [[ "$mount_needs" ]] && return 1
    [[ -x /sbin/plymouthd && -x /bin/plymouth && -x /usr/sbin/plymouth-set-default-theme ]]
}

depends() {
    return 0
}

installkernel() {
    local _modname
    # Include KMS capable drm drivers
    for _modname in $(find "$srcmods/kernel/drivers/gpu/drm" "$srcmods/extra" \( -name '*.ko' -o -name '*.ko.gz' -o -name '*.ko.xz' \) 2>/dev/null); do
        case $_modname in
            *.ko)      grep -q drm_crtc_init $_modname ;;
            *.ko.gz)  zgrep -q drm_crtc_init $_modname ;;
            *.ko.xz) xzgrep -q drm_crtc_init $_modname ;;
        esac
        if test $? -eq 0; then
            # if the hardware is present, include module even if it is not currently loaded,
            # as we could e.g. be in the installer; nokmsboot boot parameter will disable
            # loading of the driver if needed
            if [[ $hostonly ]] && modinfo -F alias $_modname | sed -e 's,\?,\.,g' -e 's,\*,\.\*,g' \
                                  | grep -qxf - /sys/bus/pci/devices/*/modalias; then
                hostonly='' instmods $_modname
                continue
            fi
            instmods $_modname
        fi
    done
}

install() {
    if grep -q nash /usr/libexec/plymouth/plymouth-populate-initrd \
        || ! grep -q PLYMOUTH_POPULATE_SOURCE_FUNCTIONS /usr/libexec/plymouth/plymouth-populate-initrd \
        || [ ! -x /usr/libexec/plymouth/plymouth-populate-initrd ]; then
        . "$moddir"/plymouth-populate-initrd
    else
        PLYMOUTH_POPULATE_SOURCE_FUNCTIONS="$dracutfunctions" \
            /usr/libexec/plymouth/plymouth-populate-initrd -t $initdir
    fi

    inst_hook pre-pivot 90 "$moddir"/plymouth-newroot.sh
    inst_hook pre-trigger 10 "$moddir"/plymouth-pretrigger.sh
    inst_hook pre-pivot 10 "$moddir"/plymouth-cleanup.sh
    inst_hook emergency 50 "$moddir"/plymouth-emergency.sh
    inst readlink
}

