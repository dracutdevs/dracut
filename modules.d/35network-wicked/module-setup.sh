#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries ip \
        pppd \
        wicked \
        wickedd \
        wickedd-auto4 \
        wickedd-dhcp4 \
        wickedd-dhcp6 \
        wickedd-nanny \
        || return 1

    # Do not add this module by default.
    return 255
}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo dbus kernel-network-modules systemd

    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module.
install() {

    # Add systemd overrides for upstream system units, replaces sed
    # !!! Note to self yet again snippets cant be used, replace with full units !!!
    # inst_simple "$moddir/wicked.conf" "$systemdsystemunitdir/wicked.service.d/dracut.conf"
    # inst_simple "$moddir/wickedd-auto4.conf" "$systemdsystemunitdir/wickedd-auto4.service.d/dracut.conf"
    # inst_simple "$moddir/wickedd-dhcp4.conf" "$systemdsystemunitdir/wickedd.dhcp4.d/wickedd-dracut.conf"
    # inst_simple "$moddir/wickedd-dhcp6.conf" "$systemdsystemunitdir/wickedd.dhcp6.d/dracut.conf"
    # inst_simple "$moddir/wickedd-nanny.conf" "$systemdsystemunitdir/wickedd.nanny.d/dracut.conf"

    inst_hook cmdline 99 "$moddir/wicked-config.sh"
    inst_hook pre-udev 99 "$moddir/wicked-run.sh"

    # Create wicked related directories.
    inst_dir /usr/share/wicked/schema
    inst_dir /usr/lib/wicked/bin
    inst_dir /var/lib/wicked

    inst_multiple -o \
        /usr/share/wicked/schema/addrconf.xml \
        /usr/share/wicked/schema/bonding.xml \
        /usr/share/wicked/schema/bridge.xml \
        /usr/share/wicked/schema/constants.xml \
        /usr/share/wicked/schema/dummy.xml \
        /usr/share/wicked/schema/ethernet.xml \
        /usr/share/wicked/schema/ethtool.xml \
        /usr/share/wicked/schema/firewall.xml \
        /usr/share/wicked/schema/gre.xml \
        /usr/share/wicked/schema/infiniband.xml \
        /usr/share/wicked/schema/interface.xml \
        /usr/share/wicked/schema/ipip.xml \
        /usr/share/wicked/schema/lldp.xml \
        /usr/share/wicked/schema/macvlan.xml \
        /usr/share/wicked/schema/modem.xml \
        /usr/share/wicked/schema/openvpn.xml \
        /usr/share/wicked/schema/ovs-bridge.xml \
        /usr/share/wicked/schema/ppp.xml \
        /usr/share/wicked/schema/protocol.xml \
        /usr/share/wicked/schema/scripts.xml \
        /usr/share/wicked/schema/sit.xml \
        /usr/share/wicked/schema/team.xml \
        /usr/share/wicked/schema/tuntap.xml \
        /usr/share/wicked/schema/types.xml \
        /usr/share/wicked/schema/vlan.xml \
        /usr/share/wicked/schema/vxlan.xml \
        /usr/share/wicked/schema/wicked.xml \
        /usr/share/wicked/schema/wireless.xml \
        "$dbussystem"/org.opensuse.Network.conf \
        "$dbussystem"/org.opensuse.Network.AUTO4.conf \
        "$dbussystem"/org.opensuse.Network.DHCP4.conf \
        "$dbussystem"/org.opensuse.Network.DHCP6.conf \
        "$dbussystem"/org.opensuse.Network.Nanny.conf \
        "$dbussystemservices"/org.opensuse.Network.AUTO4.service \
        "$dbussystemservices"/org.opensuse.Network.DHCP4.service \
        "$dbussystemservices"/org.opensuse.Network.DHCP6.service \
        "$dbussystemservices"/org.opensuse.Network.Nanny.service \
        "$systemdsystemunitdir"/wicked.service \
        "$systemdsystemunitdir/wicked@.service" \
        "$systemdsystemunitdir"/wickedd.service \
        "$systemdsystemunitdir"/wickedd-auto4.service \
        "$systemdsystemunitdir"/wickedd-dhcp4.service \
        "$systemdsystemunitdir"/wickedd-dhcp6.service \
        "$systemdsystemunitdir"/wickedd-nanny.service \
        "$systemdsystemunitdir/wickedd-pppd@.service" \
        ip pppd wicked wickedd wickedd-auto4 wickedd-dhcp4 wickedd-dhcp6 wickedd-nanny

    # Enable systemd type units.
    for i in \
        wicked.service \
        wicked@.service \
        wickedd.service \
        wickedd-auto4.service \
        wickedd-dhcp4.service \
        wickedd-dhcp6.service \
        wickedd-nanny.service \
        wickedd-pppd@.service; do
        $SYSTEMCTL -q --root "$initdir" enable "$i"
    done

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "/etc/wicked/*.xml" \
            "/etc/wicked/extensions/*" \
            "$dbusconfdir"/org.opensuse.Network.conf \
            "$dbusconfdir"/org.opensuse.Network.AUTO4.conf \
            "$dbusconfdir"/org.opensuse.Network.DHCP4.conf \
            "$dbusconfdir"/org.opensuse.Network.DHCP6.conf \
            "$dbusconfdir"/org.opensuse.Network.Nanny.conf \
            "$systemdsystemconfdir"/wicked.service \
            "$systemdsystemconfdir/wicked.service/*.conf" \
            "$systemdsystemconfdir/wicked@.service" \
            "$systemdsystemconfdir/wicked@.service/*.conf" \
            "$systemdsystemconfdir"/wickedd.service \
            "$systemdsystemconfdir/wickedd.service/*.conf" \
            "$systemdsystemconfdir"/wickedd-auto4.service \
            "$systemdsystemconfdir/wickedd-auto4.service/*.conf" \
            "$systemdsystemconfdir"/wickedd-dhcp4.service \
            "$systemdsystemconfdir/wickedd-dhcp4.service/*.conf" \
            "$systemdsystemconfdir"/wickedd-dhcp6.service \
            "$systemdsystemconfdir/wickedd-dhcp6.service/*.conf" \
            "$systemdsystemconfdir"/wickedd-nanny.service \
            "$systemdsystemconfdir/wickedd-nanny.service/*.conf" \
            "$systemdsystemconfdir/wickedd-pppd@.service" \
            "$systemdsystemconfdir/wickedd-nanny.service/*.conf"
    fi

    # TODO replace this section with systemd units
    #    for unit in "${wicked_units[@]}"; do
    #        sed -i 's/^After=.*/After=dbus.service/g' "$initdir/$unit"
    #        sed -i 's/^Before=\(.*\)/Before=\1 dracut-pre-udev.service/g' "$initdir/$unit"
    #        sed -i 's/^Wants=\(.*\)/Wants=\1 dbus.service/g' "$initdir/$unit"
    #        # shellcheck disable=SC1004
    #        sed -i -e \
    #            '/^\[Unit\]/aDefaultDependencies=no\
    #            Conflicts=shutdown.target\
    #            Before=shutdown.target' \
    #            "$initdir/$unit"
    #    done

}
