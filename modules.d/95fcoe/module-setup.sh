#!/bin/bash

# called by dracut
check() {
    local _fcoe_ctlr
    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for c in /sys/bus/fcoe/devices/ctlr_* ; do
            [ -L $c ] || continue
            _fcoe_ctlr=$c
        done
        [ -z "$_fcoe_ctlr" ] && return 255
    }

    require_binaries dcbtool fipvlan lldpad ip readlink fcoemon fcoeadm || return 1
    return 0
}

# called by dracut
depends() {
    echo network rootfs-block
    return 0
}

# called by dracut
installkernel() {
    instmods fcoe 8021q edd
}

get_vlan_parent() {
    local link=$1

    [ -d $link ] || return
    read iflink < $link/iflink
    for if in /sys/class/net/* ; do
	read idx < $if/ifindex
	if [ $idx -eq $iflink ] ; then
	    echo ${if##*/}
	fi
    done
}

# called by dracut
cmdline() {

    for c in /sys/bus/fcoe/devices/ctlr_* ; do
        [ -L $c ] || continue
        read enabled < $c/enabled
        [ $enabled -eq 0 ] && continue
        d=$(cd -P $c; echo $PWD)
        i=${d%/*}
        read mac < ${i}/address
        s=$(dcbtool gc ${i##*/} dcb | sed -n 's/^DCB State:\t*\(.*\)/\1/p')
        if [ -z "$s" ] ; then
	    p=$(get_vlan_parent ${i})
	    if [ "$p" ] ; then
	        s=$(dcbtool gc ${p} dcb | sed -n 's/^DCB State:\t*\(.*\)/\1/p')
	    fi
        fi
        if [ "$s" = "on" ] ; then
	    dcb="dcb"
        else
	    dcb="nodcb"
        fi
        echo "fcoe=${mac}:${dcb}"
    done
}

# called by dracut
install() {
    inst_multiple ip dcbtool fipvlan lldpad readlink lldptool fcoemon fcoeadm
    if [ -e "/etc/hba.conf" ]; then
        inst_libdir_file 'libhbalinux.so*'
        inst_simple "/etc/hba.conf"
    fi

    mkdir -m 0755 -p "$initdir/var/lib/lldpad"
    mkdir -m 0755 -p "$initdir/etc/fcoe"

    if [[ $hostonly_cmdline == "yes" ]] ; then
        local _fcoeconf=$(cmdline)
        [[ $_fcoeconf ]] && printf "%s\n" "$_fcoeconf" >> "${initdir}/etc/cmdline.d/95fcoe.conf"
    fi
    inst "$moddir/fcoe-up.sh" "/sbin/fcoe-up"
    inst "$moddir/fcoe-edd.sh" "/sbin/fcoe-edd"
    inst "$moddir/fcoe-genrules.sh" "/sbin/fcoe-genrules.sh"
    inst_hook pre-trigger 03 "$moddir/lldpad.sh"
    inst_hook cmdline 99 "$moddir/parse-fcoe.sh"
    inst_hook cleanup 90 "$moddir/cleanup-fcoe.sh"
    dracut_need_initqueue
}

