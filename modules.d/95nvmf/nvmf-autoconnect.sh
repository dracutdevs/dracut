#!/bin/sh
# Argument $1 is "settled", "online", or "timeout", indicating
# the queue from which the script is called.
# In the "timeout" case, try everything.
# Otherwise, try options according to the priorities below.

[ "$RD_DEBUG" != yes ] || set -x

NVMF_HOSTNQN_OK=
[ ! -f "/etc/nvme/hostnqn" ] || [ ! -f "/etc/nvme/hostid" ] || NVMF_HOSTNQN_OK=1

if [ -e /tmp/nvmf-fc-auto ] && [ "$NVMF_HOSTNQN_OK" ] \
    && [ -f /sys/class/fc/fc_udev_device/nvme_discovery ]; then
    # prio 1: cmdline override "rd.nvmf.discovery=fc,auto"
    echo add > /sys/class/fc/fc_udev_device/nvme_discovery
    [ "$1" = timeout ] || exit 0
fi
if [ -e /tmp/valid_nbft_entry_found ]; then
    # prio 2: NBFT
    /usr/sbin/nvme connect-nbft
    [ "$1" = timeout ] || exit 0
fi
if [ -f /etc/nvme/discovery.conf ] && [ $NVMF_HOSTNQN_OK ]; then
    # prio 3: discovery.conf from initrd
    /usr/sbin/nvme connect-all
    [ "$1" = timeout ] || exit 0
fi
if [ "$NVMF_HOSTNQN_OK" ] \
    && [ -f /sys/class/fc/fc_udev_device/nvme_discovery ]; then
    # prio 4: no discovery entries, try NVMeoFC autoconnect
    echo add > /sys/class/fc/fc_udev_device/nvme_discovery
fi
exit 0
