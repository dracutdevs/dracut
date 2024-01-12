#!/bin/bash

check() {
    # Only include the module if another module requires it
    return 255
}

depends() {
    echo "debug"
}

install() {
    inst_simple /etc/os-release

    inst_multiple mkdir ln dd stty mount poweroff umount setsid sync

    for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
        [ -f ${_terminfodir}/l/linux ] && break
    done
    inst_multiple -o ${_terminfodir}/l/linux

    inst_binary "${dracutbasedir}/dracut-util" "/usr/bin/dracut-util"
    ln -s dracut-util "${initdir}/usr/bin/dracut-getarg"
    ln -s dracut-util "${initdir}/usr/bin/dracut-getargs"

    inst_simple "${dracutbasedir}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh"
    inst_simple "${dracutbasedir}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh"

    inst "$moddir/test-init.sh" /sbin/init

    inst_multiple -o plymouth
}
