#!/bin/bash

# called by dracut
check() {
    [[ $mount_needs ]] && return 1

    if ! dracut_module_included "systemd"; then
        derror "systemd-timesyncd needs systemd in the initramfs"
        return 1
    fi

    return 0
}

# called by dracut
depends() {
    echo "systemd systemd-networkd"
}

installkernel() {
    return 0
}

# called by dracut
install() {
    local _mods

    inst_multiple -o \
       $systemdutildir/systemd-timesyncd \
       $systemdutildir/systemd-timedated \
       $systemdsystemunitdir/systemd-timesyncd.service \
       $systemdsystemunitdir/systemd-timedated.service \
       $systemdsystemunitdir/time-sync.target \
       timedatectl

    inst_dir /var/lib/systemd/timesync/clock \

    if [[ $hostonly ]]; then
       inst_multiple -H -o \
           /etc/systemd/timesyncd.conf \
	   /etc/systemd/timesyncd.conf.d/*.conf
           ${NULL}
    fi

    grep '^systemd-timesync:' $dracutsysrootdir/etc/passwd 2>/dev/null >> "$initdir/etc/passwd"
    grep '^systemd-timesync:' $dracutsysrootdir/etc/group >> "$initdir/etc/group"

    for i in \
        systemd-timesyncd.service \
        systemd-timedated.service \
        time-sync.target
    do
        systemctl -q --root "$initdir" enable "$i"
    done   

}
