#!/bin/bash

# called by dracut
check() {
    # If our prerequisites are not met, fail anyways.
    require_any_binary rpcbind portmap || return 1
    require_binaries rpc.statd mount.nfs mount.nfs4 umount || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in ${host_fs_types[@]}; do
            [[ "$fs" == "nfs" ]] && return 0
            [[ "$fs" == "nfs3" ]] && return 0
            [[ "$fs" == "nfs4" ]] && return 0
        done
        return 255
    }

    return 0
}

# called by dracut
depends() {
    # We depend on network modules being loaded
    echo network
}

# called by dracut
installkernel() {
    instmods nfs sunrpc ipv6 nfsv2 nfsv3 nfsv4 nfs_acl nfs_layout_nfsv41_files
}

# called by dracut
install() {
    local _i
    local _nsslibs
    inst_multiple -o portmap rpcbind rpc.statd mount.nfs \
        mount.nfs4 umount rpc.idmapd sed /etc/netconfig
    inst_multiple /etc/services /etc/nsswitch.conf /etc/rpc /etc/protocols /etc/idmapd.conf

    if [ -f /lib/modprobe.d/nfs.conf ]; then
        inst_multiple /lib/modprobe.d/nfs.conf
    else
        [ -d $initdir/etc/modprobe.d/ ] || mkdir $initdir/etc/modprobe.d
        echo "alias nfs4 nfs" > $initdir/etc/modprobe.d/nfs.conf
    fi

    inst_libdir_file 'libnfsidmap_nsswitch.so*' 'libnfsidmap/*.so' 'libnfsidmap*.so*'

    _nsslibs=$(sed -e '/^#/d' -e 's/^.*://' -e 's/\[NOTFOUND=return\]//' /etc/nsswitch.conf \
        |  tr -s '[:space:]' '\n' | sort -u | tr -s '[:space:]' '|')
    _nsslibs=${_nsslibs#|}
    _nsslibs=${_nsslibs%|}

    inst_libdir_file -n "$_nsslibs" 'libnss_*.so*'

    inst_hook cmdline 90 "$moddir/parse-nfsroot.sh"
    inst_hook pre-udev 99 "$moddir/nfs-start-rpc.sh"
    inst_hook cleanup 99 "$moddir/nfsroot-cleanup.sh"
    inst "$moddir/nfsroot.sh" "/sbin/nfsroot"
    inst "$moddir/nfs-lib.sh" "/lib/nfs-lib.sh"
    mkdir -m 0755 -p "$initdir/var/lib/nfs/rpc_pipefs"
    mkdir -m 0755 -p "$initdir/var/lib/rpcbind"
    mkdir -m 0755 -p "$initdir/var/lib/nfs/statd/sm"

    # Rather than copy the passwd file in, just set a user for rpcbind
    # We'll save the state and restart the daemon from the root anyway
    egrep '^nfsnobody:|^rpc:|^rpcuser:' /etc/passwd >> "$initdir/etc/passwd"
    egrep '^nogroup:|^rpc:|^nobody:' /etc/group >> "$initdir/etc/group"

    # rpc user needs to be able to write to this directory to save the warmstart
    # file
    chmod 770 "$initdir/var/lib/rpcbind"
    egrep -q '^rpc:' /etc/passwd \
        && egrep -q '^rpc:' /etc/group \
        && chown rpc.rpc "$initdir/var/lib/rpcbind"
    dracut_need_initqueue
}

