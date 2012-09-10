#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # If our prerequisites are not met, fail anyways.
    type -P rpcbind >/dev/null || type -P portmap >/dev/null || return 1
    type -P rpc.statd mount.nfs mount.nfs4 umount >/dev/null || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in ${host_fs_types[@]}; do
            strstr "$fs" "\|nfs"  && return 0
            strstr "$fs" "\|nfs3" && return 0
            strstr "$fs" "\|nfs4" && return 0
        done
        return 255
    }

    return 0
}

depends() {
    # We depend on network modules being loaded
    echo network
}

installkernel() {
    instmods nfs sunrpc ipv6 nfsv2 nfsv3 nfsv4 nfs_acl nfs_layout_nfsv41_files
}

install() {
    local _i
    local _nsslibs
    dracut_install -o portmap rpcbind rpc.statd mount.nfs \
        mount.nfs4 umount rpc.idmapd sed /etc/netconfig
    dracut_install /etc/services /etc/nsswitch.conf /etc/rpc /etc/protocols /etc/idmapd.conf

    if [ -f /lib/modprobe.d/nfs.conf ]; then
        dracut_install /lib/modprobe.d/nfs.conf
    else
        echo "alias nfs4 nfs" > $initdir/etc/modprobe.d/nfs.conf
    fi

    inst_libdir_file 'libnfsidmap_nsswitch.so*' 'libnfsidmap/*.so' 'libnfsidmap*.so*'

    _nsslibs=$(sed -e '/^#/d' -e 's/^.*://' -e 's/\[NOTFOUND=return\]//' /etc/nsswitch.conf \
        |  tr -s '[:space:]' '\n' | sort -u | tr -s '[:space:]' '|')
    _nsslibs=${_nsslibs#|}
    _nsslibs=${_nsslibs%|}

    inst_libdir_file -n "$_nsslibs" 'libnss*.so*'

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
    egrep '^nfsnobody:' /etc/passwd >> "$initdir/etc/passwd"
    egrep '^rpc:' /etc/passwd >> "$initdir/etc/passwd"
    egrep '^rpcuser:' /etc/passwd >> "$initdir/etc/passwd"
    #type -P nologin >/dev/null && dracut_install nologin
    egrep '^nobody:' /etc/group >> "$initdir/etc/group"
    egrep '^rpc:' /etc/group >> "$initdir/etc/group"

    # rpc user needs to be able to write to this directory to save the warmstart
    # file
    chmod 770 "$initdir/var/lib/rpcbind"
    egrep -q '^rpc:' /etc/passwd \
        && egrep -q '^rpc:' /etc/group \
        && chown rpc.rpc "$initdir/var/lib/rpcbind"
}

