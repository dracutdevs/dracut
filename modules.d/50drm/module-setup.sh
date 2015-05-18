#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    return 255
}

depends() {
    return 0
}

installkernel() {
    local _modname
    # Include KMS capable drm drivers

    drm_module_filter() {
        local _drm_drivers='drm_crtc_init'
        local _ret
        # subfunctions inherit following FDs
        local _merge=8 _side2=9
        function nmf1() {
            local _fname _fcont
            while read _fname; do
                case "$_fname" in
                    *.ko)    _fcont="$(<        $_fname)" ;;
                    *.ko.gz) _fcont="$(gzip -dc $_fname)" ;;
                    *.ko.xz) _fcont="$(xz -dc   $_fname)" ;;
                esac
                [[   $_fcont =~ $_drm_drivers
                && ! $_fcont =~ iw_handler_get_spy ]] \
                && echo "$_fname"
            done
        }
        function rotor() {
            local _f1 _f2
            while read _f1; do
                echo "$_f1"
                if read _f2; then
                    echo "$_f2" 1>&${_side2}
                fi
            done | nmf1 1>&${_merge}
        }
        # Use two parallel streams to filter alternating modules.
        set +x
        eval "( ( rotor ) ${_side2}>&1 | nmf1 ) ${_merge}>&1"
        [[ $debug ]] && set -x
        return 0
    }

    instmods amdkfd hyperv_fb

    for _modname in $(find_kernel_modules_by_path drivers/gpu/drm \
        | drm_module_filter) ; do
        # if the hardware is present, include module even if it is not currently loaded,
        # as we could e.g. be in the installer; nokmsboot boot parameter will disable
        # loading of the driver if needed
        if [[ $hostonly ]] && modinfo -F alias $_modname | sed -e 's,\?,\.,g' -e 's,\*,\.\*,g' \
            | grep -qxf - /sys/bus/pci/devices/*/modalias 2>/dev/null; then
            hostonly='' instmods $_modname
            continue
        fi
        instmods $_modname
    done
}
