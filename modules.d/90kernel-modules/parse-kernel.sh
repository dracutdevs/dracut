#!/bin/sh

_modprobe_d=/etc/modprobe.d
if [ -d /usr/lib/modprobe.d ]; then
    _modprobe_d=/usr/lib/modprobe.d
elif [ -d /lib/modprobe.d ]; then
    _modprobe_d=/lib/modprobe.d
elif ! [ -d "$_modprobe_d" ]; then
    mkdir -p "$_modprobe_d"
fi

IFS="$IFS,"
# shellcheck disable=SC2046
modprobe -a $(getargs rd.driver.pre -d rdloaddriver=) 2>&1 | vinfo
IFS="${IFS%,}"

[ -d /etc/modprobe.d ] || mkdir -p /etc/modprobe.d

for i in $(getargs rd.driver.blacklist -d rdblacklist=); do
    (
        IFS=,
        # shellcheck disable=SC2086
        printf "blacklist %s\n" $i >> "$_modprobe_d"/initramfsblacklist.conf
    )
done

for p in $(getargs rd.driver.post -d rdinsmodpost=); do
    echo "blacklist $p" >> "$_modprobe_d"/initramfsblacklist.conf
    _do_insmodpost=1
done

[ -n "$_do_insmodpost" ] && initqueue --settled --unique --onetime insmodpost.sh
unset _do_insmodpost _modprobe_d
