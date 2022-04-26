#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {
    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_any_binary /usr/lib/bluetooth/bluetoothd /usr/libexec/bluetooth/bluetoothd || return 1

    if [[ $hostonly ]]; then
        # Include by default if a Peripheral (0x500) is found of minor class:
        #  * Keyboard (0x40)
        #  * Keyboard/pointing (0xC0)
        grep -qiE 'Class=0x[0-9a-f]{3}5[4c]0' /var/lib/bluetooth/*/*/info 2> /dev/null && return 0
    fi

    return 255
}

# Module dependency requirements.
depends() {
    # This module has external dependencies on the systemd and dbus modules.
    echo systemd dbus
    # Return 0 to include the dependent modules in the initramfs.
    return 0
}

installkernel() {
    instmods bluetooth btrtl btintel btbcm bnep ath3k btusb rfcomm hidp
    inst_multiple -o \
        /lib/firmware/ar3k/AthrBT* \
        /lib/firmware/ar3k/ramps* \
        /lib/firmware/ath3k-1.fw* \
        /lib/firmware/BCM2033-MD.hex* \
        /lib/firmware/bfubase.frm* \
        /lib/firmware/BT3CPCC.bin* \
        /lib/firmware/brcm/*.hcd* \
        /lib/firmware/mediatek/mt7622pr2h.bin* \
        /lib/firmware/qca/nvm* \
        /lib/firmware/qca/crnv* \
        /lib/firmware/qca/rampatch* \
        /lib/firmware/qca/crbtfw* \
        /lib/firmware/rtl_bt/* \
        /lib/firmware/intel/ibt* \
        /lib/firmware/ti-connectivity/TIInit_* \
        /lib/firmware/nokia/bcmfw.bin* \
        /lib/firmware/nokia/ti1273.bin*
}

# Install the required file(s) for the module in the initramfs.
install() {
    # shellcheck disable=SC2064
    trap "$(shopt -p globstar)" RETURN
    shopt -q -s globstar
    local -a var_lib_files

    inst_multiple -o \
        "$dbussystem"/bluetooth.conf \
        "${systemdsystemunitdir}/bluetooth.target" \
        "${systemdsystemunitdir}/bluetooth.service" \
        bluetoothctl

    inst_multiple -o \
        /usr/libexec/bluetooth/bluetoothd \
        /usr/lib/bluetooth/bluetoothd

    if [[ $hostonly ]]; then
        var_lib_files=("$dracutsysrootdir"/var/lib/bluetooth/**)

        inst_multiple -o \
            /etc/bluetooth/main.conf \
            "$dbussystemconfdir"/bluetooth.conf \
            "${var_lib_files[@]#"$dracutsysrootdir"}"
    fi

    inst_rules 69-btattach-bcm.rules 60-persistent-input.rules

    # shellcheck disable=SC1004
    sed -i -e \
        '/^\[Unit\]/aDefaultDependencies=no\
        Conflicts=shutdown.target\
        Before=shutdown.target\
        After=dbus.service' \
        "${initdir}/${systemdsystemunitdir}/bluetooth.service"

    $SYSTEMCTL -q --root "$initdir" enable bluetooth.service
}
