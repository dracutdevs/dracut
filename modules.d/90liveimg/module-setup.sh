#!/bin/bash
# module-setup.sh for liveimg

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    echo network url-lib overlayfs-live img-lib
    return 0
}

# called by dracut
install() {
    inst_hook cmdline 29 "$moddir/parse-liveimg.sh"
    inst_script "$moddir/liveimgroot.sh" "/sbin/liveimgroot"
    dracut_need_initqueue
}

