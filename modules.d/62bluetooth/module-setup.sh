#!/bin/bash

# called by dracut
check() {
  require_binaries /usr/libexec/bluetooth/bluetoothd || return 1

  return 255
}

depends() {
  echo systemd dbus
  return 0
}

installkernel() {
  instmods bluetooth btrtl btintel btbcm bnep ath3k btusb rfcomm
  inst_multiple -o \
    /usr/lib/firmware/ar3k/AthrBT* \
    /usr/lib/firmware/ar3k/ramps* \
    /usr/lib/firmware/ath3k-1.fw \
    /usr/lib/firmware/BCM2033-MD.hex \
    /usr/lib/firmware/bfubase.frm \
    /usr/lib/firmware/BT3CPCC.bin \
    /usr/lib/firmware/brcm/*.hcd \
    /usr/lib/firmware/mediatek/mt7622pr2h.bin \
    /usr/lib/firmware/qca/nvm* \
    /usr/lib/firmware/qca/crnv* \
    /usr/lib/firmware/qca/rampatch* \
    /usr/lib/firmware/qca/crbtfw* \
    /usr/lib/firmware/rtl_bt/* \
    /usr/lib/firmware/intel/ibt* \
    /usr/lib/firmware/ti-connectivity/TIInit_* \
    /usr/lib/firmware/nokia/bcmfw.bin \
    /usr/lib/firmware/nokia/ti1273.bin
}

install() {
  inst_multiple \
    /usr/libexec/bluetooth/bluetoothd \
    /usr/lib/systemd/system/bluetooth.target \
    /usr/lib/systemd/system/bluetooth.service \
    /etc/bluetooth/main.conf \
    bluetoothctl

  inst_multiple $(find /var/lib/bluetooth)

  inst_rules 69-btattach-bcm.rules 60-persistent-input.rules

  sed -e \
'/^\[Unit\]/aDefaultDependencies=no\
Conflicts=shutdown.target\
Before=shutdown.target\
After=dbus.service' \
    /usr/lib/systemd/system/bluetooth.service > \
    "$initdir"/usr/lib/systemd/system/bluetooth.service

  systemctl --root "$initdir" enable bluetooth.service > /dev/null 2>&1
}
