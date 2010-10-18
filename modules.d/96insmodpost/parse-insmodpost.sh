#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

for p in $(getargs rdinsmodpost=); do 
    echo "blacklist $p" >> /etc/modprobe.d/initramfsblacklist.conf
    _do_insmodpost=1
done

[ -n "$_do_insmodpost" ] && /sbin/initqueue --settled --unique --onetime /sbin/insmodpost.sh
unset _do_insmodpost
