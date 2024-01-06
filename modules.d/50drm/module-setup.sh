#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
installkernel() {
    # Include KMS capable drm drivers

    if [[ ${DRACUT_ARCH:-$(uname -m)} == arm* || ${DRACUT_ARCH:-$(uname -m)} == aarch64 ]]; then
        # arm/aarch64 specific modules needed by drm
        instmods \
            "=drivers/gpu/drm/i2c" \
            "=drivers/gpu/drm/panel" \
            "=drivers/gpu/drm/bridge" \
            "=drivers/video/backlight"
    fi

    instmods amdkfd hyperv_fb "=drivers/pwm"

    # if the hardware is present, include module even if it is not currently loaded,
    # as we could e.g. be in the installer; nokmsboot boot parameter will disable
    # loading of the driver if needed
    if [[ $hostonly ]]; then
        local -a _mods
        local i modlink modname

        for i in /sys/bus/{pci/devices,platform/devices,virtio/devices,soc/devices/soc?,vmbus/devices}/*/modalias; do
            [[ -e $i ]] || continue
            [[ -n $(< "$i") ]] || continue
            mapfile -t -O "${#_mods[@]}" _mods < "$i"
        done
        if ((${#_mods[@]})); then
            # shellcheck disable=SC2068
            if hostonly="" dracut_instmods --silent -o -s "drm_crtc_init|drm_dev_register|drm_encoder_init" -S "iw_handler_get_spy" ${_mods[@]}; then
                if strstr "$(modinfo -F filename "${_mods[@]}" 2> /dev/null)" radeon.ko; then
                    hostonly='' instmods amdkfd
                fi
            fi
        fi
        # if there is a privacy screen then its driver must be loaded before the
        # kms driver will bind, otherwise its probe() will return -EPROBE_DEFER
        # note privacy screens always register, even with e.g. nokmsboot
        for i in /sys/class/drm/privacy_screen-*/device/driver/module; do
            [[ -L $i ]] || continue
            modlink=$(readlink "$i")
            modname=$(basename "$modlink")
            instmods "$modname"
        done
    else
        dracut_instmods -o -s "drm_crtc_init|drm_dev_register|drm_encoder_init" "=drivers/gpu/drm" "=drivers/staging"
        # also include privacy screen providers (see above comment)
        # atm all providers live under drivers/platform/x86
        dracut_instmods -o -s "drm_privacy_screen_register" "=drivers/platform/x86"
    fi
}
