#!/usr/bin/sh

if [ "${root%%:*}" = "liveiso" ]; then
    {
        printf 'KERNEL=="loop-control", RUN+="/usr/sbin/initqueue --settled --onetime --unique /usr/sbin/dmsquash-live-root `/usr/sbin/losetup -f --show %s`"\n' \
            ${root#liveiso:}
    } >> /etc/udev/rules.d/99-liveiso-mount.rules
fi
