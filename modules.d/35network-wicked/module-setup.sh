#!/bin/sh

# called by dracut
check() {
    require_binaries wicked || return 1

    # do not add this module by default
    return 255
}

# called by dracut
depends() {
    echo systemd dbus
    return 0
}

# called by dracut
installkernel() {
    return 0
}

# called by dracut
install() {
    inst_hook cmdline 99 "$moddir/wicked-config.sh"

    # Seems to not execute if in initqueue/settled
    inst_hook pre-udev 99 "$moddir/wicked-run.sh"

    # even with wicked configuring the interface, ip is useful
    inst_multiple ip

    inst_dir /etc/wicked/extensions
    inst_dir /usr/share/wicked/schema
    if [ -d /usr/lib/wicked/bin ]; then
        inst_dir /usr/lib/wicked/bin
        inst_multiple "/usr/lib/wicked/bin/*"
    elif [ -d /usr/libexec/wicked/bin ]; then
        inst_dir /usr/libexec/wicked/bin
        inst_multiple "/usr/libexec/wicked/bin/*"
    fi
    inst_dir /var/lib/wicked

    inst_multiple "/etc/wicked/*.xml"
    inst_multiple "/etc/wicked/extensions/*"
    if [ -f /etc/dbus-1/system.d/org.opensuse.Network.conf ]; then
        inst_multiple "/etc/dbus-1/system.d/org.opensuse.Network*"
    elif [ -f /usr/share/dbus-1/system.d/org.opensuse.Network.conf ]; then
        inst_multiple "/usr/share/dbus-1/system.d/org.opensuse.Network*"
    fi
    inst_multiple "/usr/share/wicked/schema/*"
    inst_multiple "/usr/sbin/wicked*"

    for unit in wickedd wickedd-auto4 wickedd-dhcp4 wickedd-dhcp6 wickedd-nanny; do
        unit="$systemdsystemunitdir$unit.service"
        inst_multiple "$unit"

        # shellcheck disable=SC1004
        sed -ie 's/^After=.*/After=dbus.service/' \
            -e '/^Before=/s/$/ dracut-pre-udev.service/' \
            -e '/^Wants=/s/$/ dbus.service/' \
            -e \
            '/^\[Unit\]/aDefaultDependencies=no\
            Conflicts=shutdown.target\
            Before=shutdown.target' \
            "$initdir/$unit"
    done
}
