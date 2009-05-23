#!/bin/sh

pid=$(pidof rpc.statd)
[ -n "$pid" ] && kill $pid

pid=$(pidof rpcbind)
[ -n "$pid" ] && kill $pid

mount --move /var/lib/nfs/rpc_pipefs $NEWROOT/var/lib/nfs/rpc_pipefs
