pid=$(pidof rpc.statd)
[ -n "$pid" ] && kill $pid

pid=$(pidof rpcbind)
[ -n "$pid" ] && kill $pid

if incol2 /proc/mounts /var/lib/nfs/rpc_pipefs; then 
    # try to create the destination directory
    [ -d $NEWROOT/var/lib/nfs/rpc_pipefs ] || mkdir -p $NEWROOT/var/lib/nfs/rpc_pipefs 2>/dev/null

    if [ -d $NEWROOT/var/lib/nfs/rpc_pipefs ]; then
	mount --move /var/lib/nfs/rpc_pipefs $NEWROOT/var/lib/nfs/rpc_pipefs
    else
	umount /var/lib/nfs/rpc_pipefs
    fi
fi

