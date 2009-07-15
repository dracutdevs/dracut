initrdargs="$initrdargs rd_NO_LVM rd_LVM_VG" 

if getarg rd_NO_LVM; then
    rm -f /etc/udev/rules.d/64-lvm*.rules
fi

