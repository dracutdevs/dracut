# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
xen-detect
RC=$?
if [ "$RC" = "1" ] ; then
    modprobe xenbus_probe_frontend
    modprobe xen-kbdfront
    modprobe xen-fbfront
    modprobe xen-blkfront
    modprobe xen-netfront
    modprobe xen-pcifront
fi
