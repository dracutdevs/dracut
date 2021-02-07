#!/bin/bash

check() {
    if find_binary memstrack >/dev/null; then
        dinfo "memstrack is available"
        return 0
    fi

    dinfo "memstrack is not available"
    dinfo "If you need to use rd.memdebug>=4, please install memstrack"

    return 1
}

depends() {
    return 0
}

install() {
    inst "/bin/memstrack" "/bin/memstrack"

    inst "$moddir/memstrack-start.sh" "/bin/memstrack-start"
    inst_hook cleanup 99 "$moddir/memstrack-report.sh"

    inst "$moddir/memstrack.service" "$systemdsystemunitdir/memstrack.service"
    $SYSTEMCTL -q --root "$initdir" add-wants initrd.target memstrack.service
}
