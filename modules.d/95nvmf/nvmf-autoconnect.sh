#!/bin/sh

[ -f /sys/class/fc/fc_udev_device/nvme_discovery ] || exit
echo add > /sys/class/fc/fc_udev_device/nvme_discovery
