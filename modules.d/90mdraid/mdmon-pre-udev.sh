# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
# save state dir for mdmon/mdadm for the real root
mkdir /dev/.mdadm
[ -e /var/run/mdadm ] && rm -fr /var/run/mdadm
ln -s /dev/.mdadm /var/run/mdadm
