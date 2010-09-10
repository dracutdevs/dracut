# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
if [ -e /etc/lvm/lvm.conf ] && getarg rd_NO_LVMCONF; then
    rm -f /etc/lvm/lvm.conf
fi

if getarg rd_NO_LVM; then
    info "rd_NO_LVM: removing LVM activation"
    rm -f /etc/udev/rules.d/64-lvm*.rules
else
    for dev in $(getargs rd_LVM_VG=) $(getargs rd_LVM_LV=); do
        printf '[ -e "/dev/%s" ] || exit 1\n' $dev \
            >> /initqueue-finished/lvm.sh
        {
            printf '[ -e "/dev/%s" ] || ' $dev
            printf 'warn "LVM "%s" not found"\n' $dev
        } >> /emergency/00-lvm.sh
    done
fi

