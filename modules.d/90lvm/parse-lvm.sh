#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
if [ -e /etc/lvm/lvm.conf ] && ! getargbool 1 rd.lvm.conf -d -n rd_NO_LVMCONF; then
    rm -f /etc/lvm/lvm.conf
fi

if ! getargbool 1 rd.lvm -d -n rd_NO_LVM; then
    info "rd.lvm=0: removing LVM activation"
    rm -f /etc/udev/rules.d/64-lvm*.rules
else
    for dev in $(getargs rd.lvm.vg -d rd_LVM_VG=) $(getargs rd.lvm.lv -d rd_LVM_LV=); do
        wait_for_dev "/dev/$dev"
    done
fi

