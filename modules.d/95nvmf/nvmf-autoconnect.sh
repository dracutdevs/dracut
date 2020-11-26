#!/bin/bash

[ -f /sys/class/fc/fc_udev_device/nvme_discovery ] || exit 1
echo add > /sys/class/fc/fc_udev_device/nvme_discovery
exit 0
