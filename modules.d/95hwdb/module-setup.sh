#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

check() {
    return 255
}

# called by dracut
install() {
    local hwdb_bin

    # systemd-hwdb ships the file in /etc, with /usr/lib as an alternative.
    # The alternative location is preferred, as we can consider it being user
    # configuration.
    hwdb_bin="${udevdir}"/hwdb.bin

    if [[ ! -r "${hwdb_bin}" ]]; then
        hwdb_bin="${udevconfdir}"/hwdb.bin
    fi

    if [[ $hostonly ]]; then
        inst_multiple -H "${hwdb_bin}"
    else
        inst_multiple "${hwdb_bin}"
    fi
}
