initrdargs="$initrdargs rd_NO_LUKS rd_LUKS_UUID" 

if getarg rd_NO_LUKS; then
    rm -f /etc/udev/rules.d/70-luks.rules
fi

