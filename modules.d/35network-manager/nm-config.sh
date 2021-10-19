#!/bin/sh

type nm_generate_connections > /dev/null 2>&1 || . /lib/nm-lib.sh

if [ -n "$netroot" ] || [ -e /tmp/net.ifaces ]; then
    echo rd.neednet >> /etc/cmdline.d/35-neednet.conf
fi

if getargbool 0 rd.debug -d -y rdinitdebug -d -y rdnetdebug; then
    # shellcheck disable=SC2174
    mkdir -m 0755 -p /run/NetworkManager/conf.d
    (
        echo '[.config]'
        echo 'enable=env:initrd'
        echo
        echo '[logging]'
        echo 'level=TRACE'
    ) > /run/NetworkManager/conf.d/initrd-logging.conf

    if [ -n "$DRACUT_SYSTEMD" ]; then
        # Enable tty output if a usable console is found
        # See https://github.com/coreos/fedora-coreos-tracker/issues/943
        # shellcheck disable=SC2217
        if [ -w /dev/console ] && (echo < /dev/console) > /dev/null 2> /dev/null; then
            mkdir -p /run/systemd/system/nm-initrd.service.d
            cat << EOF > /run/systemd/system/nm-initrd.service.d/tty-output.conf
[Service]
StandardOutput=tty
EOF
            systemctl --no-block daemon-reload
        fi
    fi
fi

nm_generate_connections
