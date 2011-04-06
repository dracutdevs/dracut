#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # If hostonly was requested, fail the check if we are not actually
    # booting from root.
    [ $hostonly ] && ! egrep -q '/ nfs[34 ]' /proc/mounts && return 1

    # If our prerequisites are not met, fail anyways.
    type -P rpcbind >/dev/null || type -P portmap >/dev/null || return 1
    type -P rpc.statd mount.nfs mount.nfs4 umount >/dev/null || return 1
    return 0
}

depends() {
    # We depend on network modules being loaded
    echo network
}

installkernel() {
    instmods nfs sunrpc ipv6
}

install() {
    type -P portmap >/dev/null && dracut_install portmap
    type -P rpcbind >/dev/null && dracut_install rpcbind

    dracut_install rpc.statd mount.nfs mount.nfs4 umount 
    [ -f /etc/netconfig ] && dracut_install /etc/netconfig 
    dracut_install /etc/services 
    dracut_install /etc/nsswitch.conf /etc/rpc /etc/protocols
    dracut_install rpc.idmapd /etc/idmapd.conf
    dracut_install sed

    for i in {"$libdir","$usrlibdir"}/libnfsidmap_nsswitch.so* \
        {"$libdir","$usrlibdir"}/libnfsidmap/*.so \
        {"$libdir","$usrlibdir"}/libnfsidmap*.so*; do
        [ -e "$i" ] && dracut_install "$i"
    done

    nsslibs=$(sed -e '/^#/d' -e 's/^.*://' -e 's/\[NOTFOUND=return\]//' /etc/nsswitch.conf \
        |  tr -s '[:space:]' '\n' | sort -u | tr -s '[:space:]' '|')
    nsslibs=${nsslibs#|}
    nsslibs=${nsslibs%|}

    dracut_install $(for i in $(ls {/usr,}$libdir/libnss*.so 2>/dev/null); do echo $i;done | egrep "$nsslibs")

    inst_hook cmdline 90 "$moddir/parse-nfsroot.sh"
    inst_hook pre-pivot 99 "$moddir/nfsroot-cleanup.sh"
    inst "$moddir/nfsroot" "/sbin/nfsroot"
    mkdir -m 0755 -p "$initdir/var/lib/nfs/rpc_pipefs"
    mkdir -m 0755 -p "$initdir/var/lib/rpcbind"
    mkdir -m 0755 -p "$initdir/var/lib/nfs/statd/sm"

    # Rather than copy the passwd file in, just set a user for rpcbind
    # We'll save the state and restart the daemon from the root anyway
    egrep '^root:' "$initdir/etc/passwd" 2>/dev/null || echo  'root:x:0:0::/:/bin/sh' >> "$initdir/etc/passwd"
    egrep '^nobody:' /etc/passwd >> "$initdir/etc/passwd"
    egrep '^nfsnobody:' /etc/passwd >> "$initdir/etc/passwd"
    egrep '^rpc:' /etc/passwd >> "$initdir/etc/passwd"
    egrep '^rpcuser:' /etc/passwd >> "$initdir/etc/passwd"
    #type -P nologin >/dev/null && dracut_install nologin

    # rpc user needs to be able to write to this directory to save the warmstart
    # file
    chmod 777 "$initdir/var/lib/rpcbind"
}

