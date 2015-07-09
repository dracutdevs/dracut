#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    return 0
}

depends() {
    echo udev-rules
    return 0
}

install() {
    local _d

    inst_multiple mount mknod mkdir sleep chroot \
        sed ls flock cp mv dmesg rm ln rmmod mkfifo umount readlink setsid
    inst $(command -v modprobe) /sbin/modprobe

    inst_multiple -o findmnt less kmod

    if [ ! -e "${initdir}/bin/sh" ]; then
        inst_multiple bash
        (ln -s bash "${initdir}/bin/sh" || :)
    fi

    #add common users in /etc/passwd, it will be used by nfs/ssh currently
    egrep '^root:' "$initdir/etc/passwd" 2>/dev/null || echo  'root:x:0:0::/root:/bin/sh' >> "$initdir/etc/passwd"
    egrep '^nobody:' /etc/passwd >> "$initdir/etc/passwd"

    # install our scripts and hooks
    inst_script "$moddir/init.sh" "/init"
    inst_script "$moddir/initqueue.sh" "/sbin/initqueue"
    inst_script "$moddir/loginit.sh" "/sbin/loginit"
    inst_script "$moddir/rdsosreport.sh" "/sbin/rdsosreport"
    inst_script "$moddir/memtrace-ko.sh" "/sbin/tracekomem"

    [ -e "${initdir}/lib" ] || mkdir -m 0755 -p ${initdir}/lib
    mkdir -m 0755 -p ${initdir}/lib/dracut
    mkdir -m 0755 -p ${initdir}/lib/dracut/hooks

    mkdir -p ${initdir}/tmp

    inst_simple "$moddir/dracut-lib.sh" "/lib/dracut-lib.sh"

    if ! dracut_module_included "systemd"; then
        inst_multiple switch_root || dfatal "Failed to install switch_root"
        inst_hook cmdline 10 "$moddir/parse-root-opts.sh"
    fi

    mkdir -p "${initdir}/var"

    if ! dracut_module_included "systemd"; then
        inst_multiple -o $systemdutildir/systemd-timestamp
    fi

    if [[ $realinitpath ]]; then
        for i in $realinitpath; do
            echo "rd.distroinit=$i"
        done > "${initdir}/etc/cmdline.d/distroinit.conf"
    fi

    ln -fs /proc/self/mounts "$initdir/etc/mtab"
    if [[ $ro_mnt = yes ]]; then
        echo ro >> "${initdir}/etc/cmdline.d/base.conf"
    fi

    if [ -e /etc/os-release ]; then
        . /etc/os-release
        VERSION+=" "
        PRETTY_NAME+=" "
    else
        VERSION=""
        PRETTY_NAME=""
    fi
    NAME=dracut
    ID=dracut
    VERSION+="dracut-$DRACUT_VERSION"
    PRETTY_NAME+="dracut-$DRACUT_VERSION (Initramfs)"
    VERSION_ID=$DRACUT_VERSION
    ANSI_COLOR="0;34"

    {
        echo NAME=\"$NAME\"
        echo VERSION=\"$VERSION\"
        echo ID=$ID
        echo VERSION_ID=$VERSION_ID
        echo PRETTY_NAME=\"$PRETTY_NAME\"
        echo ANSI_COLOR=\"$ANSI_COLOR\"
    } > $initdir/etc/initrd-release
    echo dracut-$DRACUT_VERSION > $initdir/lib/dracut/dracut-$DRACUT_VERSION
    ln -sf initrd-release $initdir/etc/os-release

    ## save host_devs which we need bring up
    if [[ $hostonly_cmdline == "yes" ]]; then
        if [[ -f "$initdir/lib/dracut/need-initqueue" ]] || ! dracut_module_included "systemd"; then
            (
                if dracut_module_included "systemd"; then
                    DRACUT_SYSTEMD=1
                fi
                PREFIX="$initdir"

                . "$moddir/dracut-lib.sh"

                for _dev in "${host_devs[@]}"; do
                    [[ "$_dev" == "$root_dev" ]] && continue

                    # We only actually wait for real devs - swap is only needed
                    # for resume and udev rules generated when parsing resume=
                    # argument take care of the waiting for us
                    for _dev2 in "${swap_devs[@]}"; do
                      [[ "$_dev" == "$_dev2" ]] && continue 2
                    done

                    _pdev=$(get_persistent_dev $_dev)

                    case "$_pdev" in
                        /dev/?*) wait_for_dev $_pdev;;
                        *) ;;
                    esac
                done
            )
        fi
    fi
}
