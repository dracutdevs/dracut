#!/bin/bash

# called by dracut
check() {
    is_pmem() {
        local _dev=$1

        [[ -L "/sys/dev/block/$_dev" ]] || return
        cd "$(readlink -f "/sys/dev/block/$_dev")"
        until [[ -d sys || -f devtype ]]; do
            cd ..
        done
        [[ -f devtype ]] && [[ "$(cat devtype)" == nd_* ]]
    }

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        pushd . >/dev/null
        for_each_host_dev_and_slaves is_pmem || return 255
        popd >/dev/null
    }

    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
installkernel() {
    instmods nfit =drivers/nvdimm =drivers/dax
}

# called by dracut
install() {
    dracut_need_initqueue
}
