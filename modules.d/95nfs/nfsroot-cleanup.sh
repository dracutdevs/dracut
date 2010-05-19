[ -f /tmp/nfs.rpc_pipefs_path ] && rpcpipefspath=`cat /tmp/nfs.rpc_pipefs_path`
[ -z "$rpcpipefspath" ] && rpcpipefspath=var/lib/nfs/rpc_pipefs

pid=$(pidof rpc.statd)
[ -n "$pid" ] && kill $pid

pid=$(pidof rpc.idmapd)
[ -n "$pid" ] && kill $pid

pid=$(pidof rpcbind)
[ -n "$pid" ] && kill $pid

if incol2 /proc/mounts /var/lib/nfs/rpc_pipefs; then 
    # try to create the destination directory
    [ -d $NEWROOT/$rpcpipefspath ] || mkdir -p $NEWROOT/$rpcpipefspath 2>/dev/null

    if [ -d $NEWROOT/$rpcpipefspath ]; then
	mount --move /var/lib/nfs/rpc_pipefs $NEWROOT/$rpcpipefspath
    else
	umount /var/lib/nfs/rpc_pipefs
    fi
fi

