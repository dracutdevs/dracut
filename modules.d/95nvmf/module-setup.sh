#!/bin/bash

# called by dracut
check() {
    require_binaries nvme jq || return 1

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
                read -r trtype < "$d"/transport
                break
            fi
        done
        [[ $trtype == "fc" ]] || [[ $trtype == "tcp" ]] || [[ $trtype == "rdma" ]]
    }

    has_nbft() {
        local f found=
        for f in /sys/firmware/acpi/tables/NBFT*; do
            [ -f "$f" ] || continue
            found=1
            break
        done
        [[ $found ]]
    }

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        [ -f /etc/nvme/hostnqn ] || return 255
        [ -f /etc/nvme/hostid ] || return 255
        pushd . > /dev/null
        for_each_host_dev_and_slaves is_nvmf
        local _is_nvmf=$?
        popd > /dev/null || exit
        [[ $_is_nvmf == 0 ]] || return 255
        if [ ! -f /sys/class/fc/fc_udev_device/nvme_discovery ] \
            && [ ! -f /etc/nvme/discovery.conf ] \
            && [ ! -f /etc/nvme/config.json ] && ! has_nbft; then
            echo "No discovery arguments present"
            return 255
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
    hostonly="" instmods nvme_tcp nvme_fabrics 8021q
}

# called by dracut
cmdline() {
    local _hostnqn
    local _hostid

    gen_nvmf_cmdline() {
        local _dev=$1
        local trtype
        local traddr
        local host_traddr
        local trsvcid
        local _address
        local -a _address_parts

        [[ -L "/sys/dev/block/$_dev" ]] || return 0
        cd -P "/sys/dev/block/$_dev" || return 0
        if [ -f partition ]; then
            cd ..
        fi
        for d in device/nvme*; do
            [ -L "$d" ] || continue
            if readlink "$d" | grep -q nvme-fabrics; then
                read -r trtype < "$d"/transport
                break
            fi
        done

        [ -z "$trtype" ] && return 0
        nvme list-subsys "${PWD##*/}" | while read -r _ _ trtype _address _; do
            [[ -z $trtype || $trtype != "${trtype#NQN}" ]] && continue
            unset traddr
            unset host_traddr
            unset trsvcid
            mapfile -t -d ',' _address_parts < <(printf "%s" "$_address")
            for i in "${_address_parts[@]}"; do
                [[ $i =~ ^traddr= ]] && traddr="${i#traddr=}"
                [[ $i =~ ^host_traddr= ]] && host_traddr="${i#host_traddr=}"
                [[ $i =~ ^trsvcid= ]] && trsvcid="${i#trsvcid=}"
            done
            [[ -z $traddr && -z $host_traddr && -z $trsvcid ]] && continue
            echo -n " rd.nvmf.discover=$trtype,$traddr,$host_traddr,$trsvcid"
        done
    }

    if [ -f /etc/nvme/hostnqn ]; then
        read -r _hostnqn < /etc/nvme/hostnqn
        echo -n " rd.nvmf.hostnqn=${_hostnqn}"
    fi
    if [ -f /etc/nvme/hostid ]; then
        read -r _hostid < /etc/nvme/hostid
        echo -n " rd.nvmf.hostid=${_hostid}"
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
    inst_simple -H "/etc/nvme/hostnqn"
    inst_simple -H "/etc/nvme/hostid"

    inst_multiple ip sed

    inst_script "${moddir}/nvmf-autoconnect.sh" /sbin/nvmf-autoconnect.sh
    inst_script "${moddir}/nbftroot.sh" /sbin/nbftroot

    inst_multiple nvme jq
    inst_hook cmdline 92 "$moddir/parse-nvmf-boot-connections.sh"
    inst_simple "/etc/nvme/discovery.conf"
    inst_simple "/etc/nvme/config.json"
    inst_rules /usr/lib/udev/rules.d/71-nvmf-iopolicy-netapp.rules
    inst_rules "$moddir/95-nvmf-initqueue.rules"
    dracut_need_initqueue
}
