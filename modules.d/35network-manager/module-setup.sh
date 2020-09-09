#!/bin/bash

# called by dracut
check() {
    require_binaries sed grep || return 1

    # do not add this module by default
    return 255
}

# called by dracut
depends() {
    echo systemd systemd-hostnamed dbus 
    return 0
}

# called by dracut
installkernel() {
    return 0
}

# called by dracut
install() {
    local _nm_version

    _nm_version=$(NetworkManager --version)

    # We don't need `ip` but having it is *really* useful for people debugging
    # in an emergency shell.
    inst_multiple ip sed grep

    inst NetworkManager
    inst /usr/libexec/nm-initrd-generator
    inst /usr/libexec/nm-dispatcher
    inst_multiple -o nmcli
    inst_multiple -o teamd dhclient
    inst_hook cmdline 99 "$moddir/nm-config.sh"
    inst_rules 85-nm-unmanaged.rules
    inst_libdir_file "NetworkManager/$_nm_version/libnm-device-plugin-team.so"
    inst_simple "$moddir/nm-lib.sh" "/lib/nm-lib.sh"
    inst_simple "$moddir/NetworkManager.conf" /etc/NetworkManager/NetworkManager.conf
    inst /usr/share/dbus-1/system.d/org.freedesktop.NetworkManager.conf

    inst_simple "$moddir/dracut-wait-nm.path" "$systemdsystemunitdir/dracut-wait-nm.path"
    inst_simple "$moddir/dracut-wait-nm.service" "$systemdsystemunitdir/dracut-wait-nm.service"

    # Install the dispatcher service to call dracut hooks when an
    # interface goes up
    mkdir -p "${initdir}/etc/NetworkManager/dispatcher.d/"
    inst_script "$moddir/iface-up.sh" /etc/NetworkManager/dispatcher.d/iface-up.sh
    chmod 755 "$initdir/etc/NetworkManager/dispatcher.d/iface-up.sh"

    if [[ -x "$initdir/usr/sbin/dhclient" ]]; then
        inst /usr/libexec/nm-dhcp-helper
    elif ! [[ -e "$initdir/etc/machine-id" ]]; then
        # The internal DHCP client silently fails if we
        # have no machine-id
        systemd-machine-id-setup --root="$initdir"
    fi

    # We don't install the ifcfg files from the host automatically.
    # But the user might choose to include them, so we pull in the machinery to read them.
    inst_libdir_file "NetworkManager/$_nm_version/libnm-settings-plugin-ifcfg-rh.so"

    _arch=${DRACUT_ARCH:-$(uname -m)}

    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libnss_dns.so.*" \
                     {"tls/$_arch/",tls/,"$_arch/",}"libnss_mdns4_minimal.so.*"

    inst_multiple \
        /usr/lib/systemd/system/NetworkManager.service \
        /usr/lib/systemd/system/NetworkManager-dispatcher.service \
        /usr/share/dbus-1/system-services/org.freedesktop.nm_dispatcher.service \
        /usr/share/dbus-1/system.d/nm-dispatcher.conf
    
    mkdir -p "${initdir}/$systemdsystemunitdir/NetworkManager.service.d"
    (
        echo "[Unit]"
        echo "DefaultDependencies=no"
        echo "Before=shutdown.target"
        echo "After=systemd-udev-trigger.service systemd-udev-settle.service"
        echo "[Install]"
        echo "WantedBy=sysinit.target"
    ) > "${initdir}/$systemdsystemunitdir/NetworkManager.service.d/dracut.conf"

    mkdir -p "${initdir}/$systemdsystemunitdir/NetworkManager-dispatcher.service.d"
    (
        echo "[Unit]"
        echo "DefaultDependencies=no"
    ) > "${initdir}/$systemdsystemunitdir/NetworkManager-dispatcher.service.d/dracut.conf"

    systemctl -q --root "$initdir" enable NetworkManager.service
    systemctl -q --root "$initdir" enable dracut-wait-nm.service
    systemctl -q --root "$initdir" enable dracut-wait-nm.path
}
