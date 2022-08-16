#!/bin/sh

type getcmdline > /dev/null 2>&1 || . /lib/dracut-lib.sh

nm_generate_connections() {
    rm -f /run/NetworkManager/system-connections/*
    if [ -x /usr/libexec/nm-initrd-generator ]; then
        # shellcheck disable=SC2046
        /usr/libexec/nm-initrd-generator -- $(getcmdline)
    elif [ -x /usr/lib/nm-initrd-generator ]; then
        # shellcheck disable=SC2046
        /usr/lib/nm-initrd-generator -- $(getcmdline)
    else
        warn "nm-initrd-generator not found"
    fi

    if getargbool 0 rd.neednet; then
        mkdir -p /tmp/nm.want.d
        for i in /usr/lib/NetworkManager/system-connections/* \
            /run/NetworkManager/system-connections/* \
            /etc/NetworkManager/system-connections/* \
            /etc/sysconfig/network-scripts/ifcfg-*; do
            [ -f "$i" ] || continue
            connection_uuid=$(grep '^uuid' "$i" | cut -d = -f 2)
            : > /tmp/nm.want.d/"$connection_uuid"
            [ ! -e /run/NetworkManager/initrd/neednet ] || continue

            mkdir -p "$hookdir"/initqueue/finished
            echo '[ -f /tmp/nm.done ]' > "$hookdir"/initqueue/finished/nm.sh
            mkdir -p /run/NetworkManager/initrd
            : > /run/NetworkManager/initrd/neednet # activate NM services
        done
    fi
}

nm_reload_connections() {
    [ -n "$DRACUT_SYSTEMD" ] && systemctl is-active nm-initrd.service && nmcli connection reload
}
