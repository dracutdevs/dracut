#!/bin/bash

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
    local -a wicked_units

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

    wicked_units=(
        "$systemdsystemunitdir"/wickedd.service
        "$systemdsystemunitdir"/wickedd-auto4.service
        "$systemdsystemunitdir"/wickedd-dhcp4.service
        "$systemdsystemunitdir"/wickedd-dhcp6.service
        "$systemdsystemunitdir"/wickedd-nanny.service
    )

    inst_multiple "${wicked_units[@]}"

    for unit in "${wicked_units[@]}"; do
        sed -i 's/^After=.*/After=dbus.service/g' "$initdir/$unit"
        sed -i 's/^Before=\(.*\)/Before=\1 dracut-pre-udev.service/g' "$initdir/$unit"
        sed -i 's/^Wants=\(.*\)/Wants=\1 dbus.service/g' "$initdir/$unit"
        # shellcheck disable=SC1004
        sed -i -e \
            '/^\[Unit\]/aDefaultDependencies=no\
            Conflicts=shutdown.target\
            Before=shutdown.target' \
            "$initdir/$unit"
    done
}
