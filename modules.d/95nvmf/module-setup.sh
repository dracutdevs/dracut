#!/bin/bash

# called by dracut
check() {
    require_binaries nvme || return 1
    [ -f /etc/nvme/hostnqn ] || return 255
    [ -f /etc/nvme/hostid ] || return 255

    is_nvmf() {
        local _dev=$1
        local trtype

        [[ -L "/sys/dev/block/$_dev" ]] || return 0
        cd -P "/sys/dev/block/$_dev" || return 0
        if [ -f partition ]; then
            cd ..
        fi
        for d in device/nvme*; do
            [ -L "$d" ] || continue
            if readlink "$d" | grep -q nvme-fabrics; then
                trtype=$(cat "$d"/transport)
                break
            fi
        done
        [[ $trtype == "fc" ]] || [[ $trtype == "tcp" ]] || [[ $trtype == "rdma" ]]
    }

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        pushd . > /dev/null
        for_each_host_dev_and_slaves is_nvmf
        local _is_nvmf=$?
        popd > /dev/null || exit
        [[ $_is_nvmf == 0 ]] || return 255
        if [ ! -f /sys/class/fc/fc_udev_device/nvme_discovery ]; then
            if [ ! -f /etc/nvme/discovery.conf ]; then
                echo "No discovery arguments present"
                return 255
            fi
        fi
    }
    return 0
}

# called by dracut
depends() {
    echo bash rootfs-block network
    return 0
}

# called by dracut
installkernel() {
    instmods nvme_fc lpfc qla2xxx
    hostonly="" instmods nvme_tcp nvme_fabrics
}

# called by dracut
cmdline() {
    local _hostnqn
    local _hostid

    gen_nvmf_cmdline() {
        local _dev=$1
        local trtype

        [[ -L "/sys/dev/block/$_dev" ]] || return 0
        cd -P "/sys/dev/block/$_dev" || return 0
        if [ -f partition ]; then
            cd ..
        fi
        for d in device/nvme*; do
            [ -L "$d" ] || continue
            if readlink "$d" | grep -q nvme-fabrics; then
                trtype=$(cat "$d"/transport)
                break
            fi
        done

        [ -z "$trtype" ] && return 0
        nvme list-subsys "${PWD##*/}" | while read -r _ _ trtype traddr host_traddr _; do
            [ "$trtype" != "${trtype#NQN}" ] && continue
            echo -n " nvmf.discover=$trtype,${traddr#traddr=},${host_traddr#host_traddr=}"
        done
    }

    if [ -f /etc/nvme/hostnqn ]; then
        _hostnqn=$(cat /etc/nvme/hostnqn)
        echo -n " nvmf.hostnqn=${_hostnqn}"
    fi
    if [ -f /etc/nvme/hostid ]; then
        _hostid=$(cat /etc/nvme/hostid)
        echo -n " nvmf.hostid=${_hostid}"
    fi

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        pushd . > /dev/null
        for_each_host_dev_and_slaves gen_nvmf_cmdline
        popd > /dev/null || exit
    }
}

# called by dracut
install() {
    if [[ $hostonly_cmdline == "yes" ]]; then
        local _nvmf_args
        _nvmf_args=$(cmdline)
        [[ "$_nvmf_args" ]] && printf "%s" "$_nvmf_args" >> "${initdir}/etc/cmdline.d/95nvmf-args.conf"
    fi
    inst_simple "/etc/nvme/hostnqn"
    inst_simple "/etc/nvme/hostid"

    inst_multiple ip sed

    inst_script "${moddir}/nvmf-autoconnect.sh" /sbin/nvmf-autoconnect.sh

    inst_multiple nvme
    inst_hook cmdline 99 "$moddir/parse-nvmf-boot-connections.sh"
    inst_simple "/etc/nvme/discovery.conf"
    inst_rules /usr/lib/udev/rules.d/71-nvmf-iopolicy-netapp.rules
    inst_rules "$moddir/95-nvmf-initqueue.rules"
    dracut_need_initqueue
}
