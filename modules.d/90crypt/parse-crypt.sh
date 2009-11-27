#!/bin/sh
if getarg rd_NO_LUKS; then
    info "rd_NO_LUKS: removing cryptoluks activation"
    rm -f /etc/udev/rules.d/70-luks.rules
fi

