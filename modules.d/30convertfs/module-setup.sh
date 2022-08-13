#!/bin/sh

# called by dracut
check() {
    [ -n "$mount_needs" ] && return 1
    return 255
}

# called by dracut
depends() {
    echo base
}

# called by dracut
install() {
    inst_multiple find ldconfig mv rm cp ln
    inst_hook pre-pivot 99 "$moddir/do-convertfs.sh"
    inst_script "$moddir/convertfs.sh" /usr/bin/convertfs
}
