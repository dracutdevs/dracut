#!/bin/sh
# Argument $1 is "settled", "online", or "timeout", indicating
# the queue from which the script is called.
# In the "timeout" case, try everything.
# Otherwise, try options according to the priorities below.

[ "$RD_DEBUG" != yes ] || set -x

if [ "$1" = timeout ]; then
    [ ! -f /sys/class/fc/fc_udev_device/nvme_discovery ] \
        || echo add > /sys/class/fc/fc_udev_device/nvme_discovery
    /usr/sbin/nvme connect-all
    exit 0
fi

NVMF_HOSTNQN_OK=
[ ! -f "/etc/nvme/hostnqn" ] || [ ! -f "/etc/nvme/hostid" ] || NVMF_HOSTNQN_OK=1

# Only nvme-cli 2.5 or newer supports the options --nbft and --no-nbft
# for the connect-all command.
# Make sure we don't use unsupported options with earlier versions.
NBFT_SUPPORTED=
# shellcheck disable=SC2016
/usr/sbin/nvme connect-all --help 2>&1 | sed -n '/[[:space:]]--nbft[[:space:]]/q1;$q0' \
    || NBFT_SUPPORTED=1

if [ -e /tmp/nvmf-fc-auto ] && [ "$NVMF_HOSTNQN_OK" ] \
    && [ -f /sys/class/fc/fc_udev_device/nvme_discovery ]; then
    # prio 1: cmdline override "rd.nvmf.discovery=fc,auto"
    echo add > /sys/class/fc/fc_udev_device/nvme_discovery
    exit 0
fi
if [ "$NBFT_SUPPORTED" ] && [ -e /tmp/valid_nbft_entry_found ]; then
    # prio 2: NBFT
    /usr/sbin/nvme connect-all --nbft
    exit 0
fi
if [ -f /etc/nvme/discovery.conf ] || [ -f /etc/nvme/config.json ] \
    && [ "$NVMF_HOSTNQN_OK" ]; then
    # prio 3: configuration from initrd and/or kernel command line
    # We can get here even if "rd.nvmf.nonbft" was given, thus use --no-nbft
    if [ "$NBFT_SUPPORTED" ]; then
        /usr/sbin/nvme connect-all --no-nbft
    else
        /usr/sbin/nvme connect-all
    fi
    exit 0
fi
if [ "$NVMF_HOSTNQN_OK" ] \
    && [ -f /sys/class/fc/fc_udev_device/nvme_discovery ]; then
    # prio 4: no discovery entries, try NVMeoFC autoconnect
    echo add > /sys/class/fc/fc_udev_device/nvme_discovery
fi
exit 0
