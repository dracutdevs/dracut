#!/bin/bash

check() {
    if ! require_binaries pgrep pkill memstrack; then
        dinfo "memstrack is not available"
        dinfo "If you need to use rd.memdebug>=4, please install memstrack and procps-ng"
        return 1
    fi

    return 0
}

depends() {
    echo systemd bash
    return 0
}

install() {
    inst_multiple pgrep pkill
    inst "/bin/memstrack" "/bin/memstrack"

    inst "$moddir/memstrack-start.sh" "/bin/memstrack-start"
    inst_hook cleanup 99 "$moddir/memstrack-report.sh"

    inst "$moddir/memstrack.service" "$systemdsystemunitdir/memstrack.service"

    $SYSTEMCTL -q --root "$initdir" add-wants initrd.target memstrack.service
}
