#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

for i in $(getargs rd.driver.pre rdloaddriver=); do 
    ( 
        IFS=,
        for p in $i; do 
            modprobe $p 2>&1 | vinfo
        done
    )
done

for i in $(getargs rd.driver.blacklist rdblacklist=); do 
    (
        IFS=,
        for p in $i; do 
            echo "blacklist $p" >> /etc/modprobe.d/initramfsblacklist.conf
        done
    )
done

for p in $(getargs rd.driver.post rdinsmodpost=); do 
    echo "blacklist $p" >> /etc/modprobe.d/initramfsblacklist.conf
    _do_insmodpost=1
done

[ -n "$_do_insmodpost" ] && initqueue --settled --unique --onetime insmodpost.sh
unset _do_insmodpost
