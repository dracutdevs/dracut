#!/bin/sh

pid=$(pidof rpc.statd)
[ -n "$pid" ] && kill $pid

pid=$(pidof rpcbind)
[ -n "$pid" ] && kill $pid

mkdir -p 

if [ -d $NEWROOT/var/lib/nfs/rpc_pipefs ]; then
    mount --move /var/lib/nfs/rpc_pipefs $NEWROOT/var/lib/nfs/rpc_pipefs
else
    umount /var/lib/nfs/rpc_pipefs
fi

