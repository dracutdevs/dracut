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
