#!/bin/bash

# called by dracut
check() {
    require_binaries nvme || return 1
    [ -f /etc/nvme/hostnqn ] || return 255
    [ -f /etc/nvme/hostid ] || return 255

    is_nvme_fc() {
        local _dev=$1
        local traddr

        [[ -L "/sys/dev/block/$_dev" ]] || return 0
        cd -P "/sys/dev/block/$_dev" || return 0
        if [ -f partition ] ; then
            cd ..
        fi
        for d in device/nvme* ; do
            [ -L "$d" ] || continue
            if readlink "$d" | grep -q nvme-fabrics ; then
                traddr=$(cat "$d"/address)
		break
	    fi
	done
        [[ "${traddr#traddr=nn-}" != "$traddr" ]]
    }

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        pushd . >/dev/null
        for_each_host_dev_and_slaves is_nvme_fc
        local _is_nvme_fc=$?
        popd >/dev/null
        [[ $_is_nvme_fc == 0 ]] || return 255
        if [ ! -f /sys/class/fc/fc_udev_device/nvme_discovery ] ; then
            if [ ! -f /etc/nvme/discovery.conf ] ; then
                echo "No discovery arguments present"
                return 255
            fi
        fi
    }
    return 0
}

# called by dracut
depends() {
    echo bash rootfs-block
    return 0
}

# called by dracut
installkernel() {
    instmods nvme_fc lpfc qla2xxx
}

# called by dracut
cmdline() {
    local _hostnqn
    local _hostid
    if [ -f /etc/nvme/hostnqn ] ; then
        _hostnqn=$(cat /etc/nvme/hostnqn)
        echo -n " nvmf.hostnqn=${_hostnqn}"
    fi
    if [ -f /etc/nvme/hostid ] ; then
        _hostid=$(cat /etc/nvme/hostid)
        echo -n " nvmf.hostid=${_hostid}"
    fi
    echo ""
}

# called by dracut
install() {
    if [[ $hostonly_cmdline == "yes" ]]; then
	local _nvmf_args=$(cmdline)
	[[ "$_nvmf_args" ]] && printf "%s" "$_nvmf_args" >> "${initdir}/etc/cmdline.d/95nvmf-args.conf"
    fi
    inst_simple "/etc/nvme/hostnqn"
    inst_simple "/etc/nvme/hostid"

    inst_multiple nvme
    inst_multiple -o \
        "$systemdsystemunitdir/nvm*-connect@.service" \
        "$systemdsystemunitdir/nvm*-connect.target"
    inst_hook cmdline 99 "$moddir/parse-nvmf-boot-connections.sh"
    inst_simple "/etc/nvme/discovery.conf"
    inst_rules /usr/lib/udev/rules.d/70-nvm*-autoconnect.rules
    inst_rules /usr/lib/udev/rules.d/71-nvmf-iopolicy-netapp.rules
    dracut_need_initqueue
}
