#!/bin/sh
exec > /dev/console 2>&1
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
strstr() { [ "${1#*"$2"*}" != "$1" ]; }
CMDLINE=$(while read -r line; do echo "$line"; done < /proc/cmdline)
export TERM=linux
export PS1='initramfs-test:\w\$ '
stty sane
echo "made it to the rootfs! Powering down."

testnum=$(grep -Eo "rd.dracut.test.num=[^[:space:]]+" /proc/cmdline | sed -nr 's/.*=(.*)/\1/p')
netmodule=$(grep -Eo "rd.dracut.test.net-module=[^[:space:]]+" /proc/cmdline | sed -nr 's/.*=(.*)/\1/p')

(
    echo OK

    ip -o -4 address show scope global | while read -r _ if rest; do echo "$if"; done | sort

    case "$testnum" in
        1)
            ping -c 2 192.168.50.1 > /dev/null
            echo PING1=$?
            ping -c 2 192.168.54.1 > /dev/null
            echo PING2=$?
            ping -c 2 192.168.55.1 > /dev/null
            echo PING3=$?
            ping -c 2 192.168.56.1 > /dev/null
            echo PING4=$?
            ping -c 2 192.168.57.1 > /dev/null
            echo PING5=$?
            ;;
        2)
            ping -c 2 192.168.51.1 > /dev/null
            echo PING1=$?
            ip link show net3 | grep "master bond0" > /dev/null
            echo NET3=$?
            ip link show net4 | grep "master bond0" > /dev/null
            echo NET4=$?
            ;;
        3)
            ping -c 2 192.168.51.1 > /dev/null
            echo PING1=$?
            ip link show net1 | grep "master br0" > /dev/null
            echo NET1=$?
            ip link show net5 | grep "master br0" > /dev/null
            echo NET5=$?

            ;;
    esac

    case "$netmodule" in
        network-legacy)
            for i in /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-*; do
                basename "$i"
                grep -v 'UUID=' "$i"
            done
            ;;
    esac

    echo EOF
) | dd oflag=direct,dsync of=/dev/sda

strstr "$CMDLINE" "rd.shell" && sh -i
poweroff -f
