initrdargs="$initrdargs rd_NO_LVM rd_LVM_VG" 

if getarg rd_NO_LVM; then
    info "rd_NO_LVM: removing LVM activation"
    rm -f /etc/udev/rules.d/64-lvm*.rules
fi

