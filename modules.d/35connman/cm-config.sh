#!/bin/sh

type cm_generate_connections > /dev/null 2>&1 || . /lib/cm-lib.sh

if [ -n "$netroot" ] || [ -e /tmp/net.ifaces ]; then
    echo rd.neednet >> /etc/cmdline.d/connman.conf
fi

if getargbool 0 rd.debug -d -y rdinitdebug -d -y rdnetdebug; then
    if [ -n "$DRACUT_SYSTEMD" ]; then
        # Enable tty output if a usable console is found
        # shellcheck disable=SC2217
        if [ -w /dev/console ] && (echo < /dev/console) > /dev/null 2> /dev/null; then
            mkdir -p /run/systemd/system/cm-initrd.service.d
            cat << EOF > /run/systemd/system/cm-initrd.service.d/tty-output.conf
[Service]
StandardOutput=tty
EOF
            systemctl --no-block daemon-reload
        fi
    fi
fi

cm_generate_connections
