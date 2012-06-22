#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    vm=$(systemd-detect-virt --vm &>/dev/null)
    (($? != 0)) && return 255
    [[ $vm = "qemu" ]] && return 0
    [[ $vm = "kvm" ]] && return 0
    return 255
}

installkernel() {
    # qemu specific modules
    hostonly='' instmods virtio_net e1000 8139cp pcnet32 e100 ne2k_pci
}
