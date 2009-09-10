if getarg rd_NO_DM; then
    info "rd_NO_DM: removing DM RAID activation"
    rm /etc/udev/rules.d/61-dmraid*.rules
fi