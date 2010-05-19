if getarg rd_NO_LVM; then
    info "rd_NO_LVM: removing LVM activation"
    rm -f /etc/udev/rules.d/64-lvm*.rules
fi

if [ -e /etc/lvm/lvm.conf ] && getarg rd_NO_LVMCONF; then
    rm -f /etc/lvm/lvm.conf
fi


