#!/bin/bash

# This module is deprecated. Modern replacements are NetworkManager keyfiles and
# systemd network files. It must now be explicitly opted in by the user to be
# added to the initrd.

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    echo "network"
    return 0
}

# called by dracut
install() {
    inst_binary awk
    inst_hook pre-pivot 85 "$moddir/write-ifcfg.sh"
}
