#!/bin/sh

is_mpath() {
    local _dev=$1 _uuid
    [ -e /sys/dev/block/"$_dev"/dm/uuid ] || return 1
    read -r _uuid < /sys/dev/block/"$_dev"/dm/uuid
    [ "${_uuid#mpath-}" != "$_uuid" ] && return 0
    return 1
}

majmin_to_mpath_dev() {
    local _dev
    for i in /dev/mapper/*; do
        [ "$i" = /dev/mapper/control ] && continue
        _dev=$(get_maj_min "$i")
        if [ "$_dev" = "$1" ]; then
            echo "$i"
            return
        fi
    done
}

# called by dracut
check() {
    [ -n "$hostonly" ] || [ -n "$mount_needs" ] && {
        for_each_host_dev_and_slaves is_mpath || return 255
    }

    # if there's no multipath binary, no go.
    require_binaries multipath || return 1
    require_binaries kpartx || return 1

    return 0
}

# called by dracut
depends() {
    echo rootfs-block dm
    return 0
}

# called by dracut
cmdline() {
    for m in scsi_dh_alua scsi_dh_emc scsi_dh_rdac dm_multipath; do
        if grep -m 1 -q "$m" /proc/modules; then
            printf 'rd.driver.pre=%s ' "$m"
        fi
    done
}

# called by dracut
installkernel() {
    local _arch=${DRACUT_ARCH:-$(uname -m)}
    local _funcs='scsi_register_device_handler|dm_dirty_log_type_register|dm_register_path_selector|dm_register_target'

    [ "$_arch" = "s390" ] && [ "$_arch" = "s390x" ] && _s390drivers="=drivers/s390/scsi"

    hostonly='' dracut_instmods -o -s "$_funcs" "=drivers/scsi" "=drivers/md" ${_s390drivers:+"$_s390drivers"}
}

mpathconf_installed() {
    command -v mpathconf > /dev/null
}

# called by dracut
install() {
    local config_dir _allow

    add_hostonly_mpath_conf() {
        if is_mpath "$1"; then
            local _dev

            _dev=$(majmin_to_mpath_dev "$1")
            [ -z "$_dev" ] && return
            _allow="$_allow $_dev"
            _allow="${_allow% }"
        fi
    }

    config_dir="$(multipath -t 2> /dev/null | {
        while read -r k v; do
            [ "$k" = "config_dir" ] || continue
            v="${v#\"}"
            echo "${v%\"}"
            break
        done
    })"
    [ -d "$config_dir" ] || config_dir=/etc/multipath/conf.d

    inst_multiple \
        pkill \
        pidof \
        kpartx \
        dmsetup \
        multipath \
        multipathd

    inst_multiple -o \
        mpath_wait \
        mpathconf \
        mpathpersist \
        xdrgetprio \
        xdrgetuid \
        /etc/xdrdevices.conf \
        /etc/multipath.conf \
        /etc/multipath/* \
        "$config_dir"/*

    mpathconf_installed \
        && [ -n "$hostonly" ] && [ "$hostonly_mode" = "strict" ] && {
        for_each_host_dev_and_slaves_all add_hostonly_mpath_conf
        if [ -n "$_allow" ]; then
            local _args _dev
            for _dev in $_allow; do
                _args="$_args --allow $_dev"
            done
            # shellcheck disable=SC2086
            mpathconf $_args --outfile "${initdir}"/etc/multipath.conf
        fi
    }

    inst "$(command -v partx)" /sbin/partx

    inst_libdir_file "libmultipath*" "multipath/*"
    inst_libdir_file 'libgcc_s.so*'

    if [ -n "$hostonly_cmdline" ]; then
        local _conf
        _conf=$(cmdline)
        [ -n "$_conf" ] && echo "$_conf" >> "${initdir}/etc/cmdline.d/90multipath.conf"
    fi

    if dracut_module_included "systemd"; then
        if mpathconf_installed; then
            inst_simple "${moddir}/multipathd-configure.service" "${systemdsystemunitdir}/multipathd-configure.service"
            $SYSTEMCTL -q --root "$initdir" enable multipathd-configure.service
        fi
        inst_simple "${moddir}/multipathd.service" "${systemdsystemunitdir}/multipathd.service"
        $SYSTEMCTL -q --root "$initdir" enable multipathd.service
    else
        inst_hook pre-trigger 02 "$moddir/multipathd.sh"
        inst_hook cleanup 02 "$moddir/multipathd-stop.sh"
    fi

    inst_hook cleanup 80 "$moddir/multipathd-needshutdown.sh"
    inst_hook shutdown 20 "$moddir/multipath-shutdown.sh"

    inst_rules 40-multipath.rules 56-multipath.rules \
        62-multipath.rules 65-multipath.rules \
        66-kpartx.rules 67-kpartx-compat.rules \
        11-dm-mpath.rules 11-dm-parts.rules
}
