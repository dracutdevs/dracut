#!/bin/sh
: > /dev/watchdog

. /lib/dracut-lib.sh

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
command -v plymouth > /dev/null 2>&1 && plymouth --quit
exec > /dev/console 2>&1

systemctl --failed --no-legend --no-pager > /failed

if ! ismounted /usr; then
    echo "**************************FAILED**************************"
    echo "/usr not mounted!!"
    cat /proc/mounts
    echo "**************************FAILED**************************"
else
    if [ -s /failed ]; then
        echo "**************************FAILED**************************"
        cat /failed
        echo "**************************FAILED**************************"

    else
        echo "dracut-root-block-success" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
        echo "All OK"
    fi
fi

export TERM=linux
export PS1='initramfs-test:\w\$ '
[ -f /etc/mtab ] || ln -sfn /proc/mounts /etc/mtab
[ -f /etc/fstab ] || ln -sfn /proc/mounts /etc/fstab
stty sane
echo "made it to the rootfs!"
if getargbool 0 rd.shell; then
    strstr "$(setsid --help)" "control" && CTTY="-c"
    setsid $CTTY sh -i
fi
echo "Powering down."
poweroff -f
