#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    # We do not depend on any modules - just some root
    return 0
}

# called by dracut
installkernel() {
    hostonly='' instmods overlay
}

# called by dracut
install() {
    inst_hook pre-pivot 10 "$moddir/overlay-mount.sh"
}
