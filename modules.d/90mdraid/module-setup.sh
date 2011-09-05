#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # No mdadm?  No mdraid support.
    type -P mdadm >/dev/null || return 1

    . $dracutfunctions
    [[ $debug ]] && set -x

    is_mdraid() { [[ -d "/sys/dev/block/$1/md" ]]; }

    [[ $hostonly ]] && {
        _rootdev=$(find_root_block_device)
        if [[ $_rootdev ]]; then
            # root lives on a block device, so we can be more precise about
            # hostonly checking
            check_block_and_slaves is_mdraid "$_rootdev" || return 1
        else
            # root is not on a block device, use the shotgun approach
            blkid | grep -q '"[^"]*_raid_member"' || return 1
        fi
    }

    return 0
}

depends() {
    echo rootfs-block
    return 0
}

installkernel() {
    instmods =drivers/md
}

install() {
    dracut_install mdadm partx cat


     # XXX: mdmon really needs to run as non-root?
     #      If so, write only the user it needs in the initrd's /etc/passwd (and maybe /etc/group)
     #      in a similar fashion to modules.d/95nfs.  Do not copy /etc/passwd and /etc/group from
     #      the system into the initrd.
     #      dledford has hardware to test this, so he should be able to clean this up.
     # inst /etc/passwd
     # inst /etc/group

    if [ ! -x /lib/udev/vol_id ]; then
        inst_rules 64-md-raid.rules
        # remove incremental assembly from stock rules, so they don't shadow
        # 65-md-inc*.rules and its fine-grained controls, or cause other problems
        # when we explicitly don't want certain components to be incrementally
        # assembled
        sed -i -e '/^ENV{ID_FS_TYPE}==.*ACTION=="add".*RUN+="\/sbin\/mdadm --incremental $env{DEVNAME}"$/d' "${initdir}/lib/udev/rules.d/64-md-raid.rules"
    fi

    inst_rules "$moddir/65-md-incremental-imsm.rules"

    # guard against pre-3.0 mdadm versions, that can't handle containers
    if ! mdadm -Q -e imsm /dev/null &> /dev/null; then
        inst_hook pre-trigger 30 "$moddir/md-noimsm.sh"
    fi
    if ! mdadm -Q -e ddf /dev/null &> /dev/null; then
        inst_hook pre-trigger 30 "$moddir/md-noddf.sh"
    fi

    if [[ $hostonly ]] || [[ $mdadmconf = "yes" ]]; then
        if [ -f /etc/mdadm.conf ]; then
            inst /etc/mdadm.conf
        else
            [ -f /etc/mdadm/mdadm.conf ] && inst /etc/mdadm/mdadm.conf /etc/mdadm.conf
        fi
    fi

    if [ -x  /sbin/mdmon ] ; then
        dracut_install mdmon
    fi
    inst_hook pre-udev 30 "$moddir/mdmon-pre-udev.sh"

    inst "$moddir/mdraid_start.sh" /sbin/mdraid_start
    inst "$moddir/mdadm_auto.sh" /sbin/mdadm_auto
    inst "$moddir/md_finished.sh" /sbin/md_finished.sh
    inst_hook pre-trigger 30 "$moddir/parse-md.sh"
    inst "$moddir/mdraid-cleanup.sh" /sbin/mdraid-cleanup
    inst_hook shutdown 30 "$moddir/md-shutdown.sh"
}

