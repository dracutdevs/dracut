#!/bin/bash

# called by dracut
check() {
    # No point trying to support lvm if the binaries are missing
    require_binaries lvm sort tr awk || return 1

    return 255
}

# called by dracut
depends() {
    echo lvm
    return 0
}

# called by dracut
install() {
    inst_multiple sort tr awk
    inst_script "$moddir/start-thinpool-monitor.sh" "/bin/start-thinpool-monitor"

    inst "$moddir/start-thinpool-monitor.service" "$systemdsystemunitdir/start-thinpool-monitor.service"
    $SYSTEMCTL -q --root "$initdir" add-wants initrd.target start-thinpool-monitor.service
}
