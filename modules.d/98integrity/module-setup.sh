#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    echo masterkey securityfs selinux
    return 0
}

# called by dracut
install() {
    inst_hook pre-pivot 61 "$moddir/evm-enable.sh"
    inst_hook pre-pivot 62 "$moddir/ima-policy-load.sh"
}
