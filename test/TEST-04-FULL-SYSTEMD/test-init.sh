#!/bin/sh
>/dev/watchdog
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
strstr() { [ "${1##*"$2"*}" != "$1" ]; }
CMDLINE=$(while read line; do echo $line;done < /proc/cmdline)
plymouth --quit
exec </dev/console >/dev/console 2>&1

ismounted() {
    while read a m a; do
        [ "$m" = "$1" ] && return 0
    done < /proc/mounts
    return 1
}

systemctl --failed --no-legend --no-pager > /failed

if ismounted /usr && [ ! -s /failed ]; then
    echo "dracut-root-block-success" >/dev/sdc
fi

journalctl --full --no-pager -o short-monotonic

if [ -s /failed ]; then
    echo "**************************FAILED**************************"
    cat /failed
    echo "**************************FAILED**************************"
fi

ls -al /run/systemd/system

export TERM=linux
export PS1='initramfs-test:\w\$ '
[ -f /etc/mtab ] || ln -sfn /proc/mounts /etc/mtab
[ -f /etc/fstab ] || ln -sfn /proc/mounts /etc/fstab
stty sane
echo "made it to the rootfs!"
if strstr "$CMDLINE" "rd.shell"; then
#	while sleep 1; do sleep 1;done
	strstr "$(setsid --help)" "control" && CTTY="-c"
	setsid $CTTY sh -i
fi
set -x
/usr/bin/systemctl poweroff
echo "Powering down."
