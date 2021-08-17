#!/bin/bash

# called by dracut
check() {
    # If our prerequisites are not met, fail anyways.
    require_binaries iscsi-iname iscsiadm iscsid || return 1

    # If hostonly was requested, fail the check if we are not actually
    # booting from root.

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        pushd . > /dev/null
        for_each_host_dev_and_slaves block_is_iscsi
        local _is_iscsi=$?
        popd > /dev/null || exit
        [[ $_is_iscsi == 0 ]] || return 255
    }
    return 0
}

get_ibft_mod() {
    local ibft_mac=$1
    local iface_mac iface_mod
    # Return the iSCSI offload module for a given MAC address
    for iface_desc in $(iscsiadm -m iface | cut -f 2 -d ' '); do
        iface_mod=${iface_desc%%,*}
        iface_mac=${iface_desc#*,}
        iface_mac=${iface_mac%%,*}
        if [ "$ibft_mac" = "$iface_mac" ]; then
            echo "$iface_mod"
            return 0
        fi
    done
}

install_ibft() {
    # When iBFT / iscsi_boot is detected:
    # - Use 'ip=ibft' to set up iBFT network interface
    #   Note: bnx2i is using a different MAC address of iSCSI offloading
    #         so the 'ip=ibft' parameter must not be set
    # - specify firmware booting cmdline parameter

    for d in /sys/firmware/*; do
        if [ -d "${d}"/ethernet0 ]; then
            read -r ibft_mac < "${d}"/ethernet0/mac
            ibft_mod=$(get_ibft_mod "$ibft_mac")
        fi
        if [ -z "$ibft_mod" ] && [ -d "${d}"/ethernet1 ]; then
            read -r ibft_mac < "${d}"/ethernet1/mac
            ibft_mod=$(get_ibft_mod "$ibft_mac")
        fi
        if [ -d "${d}"/initiator ]; then
            if [ "${d##*/}" = "ibft" ] && [ "$ibft_mod" != "bnx2i" ]; then
                echo -n "rd.iscsi.ibft=1 "
            fi
            echo -n "rd.iscsi.firmware=1 "
        fi
    done
}

install_iscsiroot() {
    local devpath=$1
    local scsi_path iscsi_lun session c d conn host flash
    local iscsi_session iscsi_address iscsi_port iscsi_targetname

    scsi_path=${devpath%%/block*}
    [ "$scsi_path" = "$devpath" ] && return 1
    iscsi_lun=${scsi_path##*:}
    [ "$iscsi_lun" = "$scsi_path" ] && return 1
    session=${devpath%%/target*}
    [ "$session" = "$devpath" ] && return 1
    iscsi_session=${session##*/}
    [ "$iscsi_session" = "$session" ] && return 1
    host=${session%%/session*}
    [ "$host" = "$session" ] && return 1
    iscsi_host=${host##*/}

    for flash in "${host}"/flashnode_sess-*; do
        [ -f "$flash" ] || continue
        [ ! -e "$flash/is_boot_target" ] && continue
        is_boot=$(cat "$flash"/is_boot_target)
        if [ "$is_boot" -eq 1 ]; then
            # qla4xxx flashnode session; skip iBFT discovery
            iscsi_initiator=$(cat /sys/class/iscsi_host/"${iscsi_host}"/initiatorname)
            echo "rd.iscsi.initiator=${iscsi_initiator}"
            return
        fi
    done

    for d in "${session}"/*; do
        case $d in
            *connection*)
                c=${d##*/}
                conn=${d}/iscsi_connection/${c}
                if [ -d "${conn}" ]; then
                    iscsi_address=$(cat "${conn}"/persistent_address)
                    iscsi_port=$(cat "${conn}"/persistent_port)
                fi
                ;;
            *session)
                if [ -d "${d}"/"${iscsi_session}" ]; then
                    iscsi_initiator=$(cat "${d}"/"${iscsi_session}"/initiatorname)
                    iscsi_targetname=$(cat "${d}"/"${iscsi_session}"/targetname)
                fi
                ;;
        esac
    done

    [ -z "$iscsi_address" ] && return
    ip_params_for_remote_addr "$iscsi_address"

    if [ -n "$iscsi_address" -a -n "$iscsi_targetname" ]; then
        if [ -n "$iscsi_port" -a "$iscsi_port" -eq 3260 ]; then
            iscsi_port=
        fi
        if [ -n "$iscsi_lun" -a "$iscsi_lun" -eq 0 ]; then
            iscsi_lun=
        fi
        # In IPv6 case rd.iscsi.initatior= must pass address in [] brackets
        case "$iscsi_address" in
            *:*)
                iscsi_address="[$iscsi_address]"
                ;;
        esac
        # Must be two separate lines, so that "sort | uniq" commands later
        # can sort out rd.iscsi.initiator= duplicates
        echo "rd.iscsi.initiator=${iscsi_initiator}"
        echo "netroot=iscsi:${iscsi_address}::${iscsi_port}:${iscsi_lun}:${iscsi_targetname}"
        echo "rd.neednet=1"
    fi
    return 0
}

install_softiscsi() {
    [ -d /sys/firmware/ibft ] && return 0

    is_softiscsi() {
        local _dev=$1
        local iscsi_dev

        [[ -L "/sys/dev/block/$_dev" ]] || return
        iscsi_dev=$(
            cd -P /sys/dev/block/"$_dev" || exit
            echo "$PWD"
        )
        install_iscsiroot "$iscsi_dev"
    }

    for_each_host_dev_and_slaves_all is_softiscsi || return 255
    return 0
}

# called by dracut
depends() {
    echo network rootfs-block
}

# called by dracut
installkernel() {
    local _arch=${DRACUT_ARCH:-$(uname -m)}
    local _funcs='iscsi_register_transport'

    instmods bnx2i qla4xxx cxgb3i cxgb4i be2iscsi qedi
    hostonly="" instmods iscsi_tcp iscsi_ibft crc32c iscsi_boot_sysfs

    if [ "$_arch" = "s390" -o "$_arch" = "s390x" ]; then
        _s390drivers="=drivers/s390/scsi"
    fi

    dracut_instmods -o -s ${_funcs} =drivers/scsi ${_s390drivers:+"$_s390drivers"}
}

# called by dracut
cmdline() {
    local _iscsiconf
    _iscsiconf=$(install_ibft)
    {
        if [ "$_iscsiconf" ]; then
            echo "${_iscsiconf}"
        else
            install_softiscsi
        fi
    } | sort | uniq
}

# called by dracut
install() {
    inst_multiple -o iscsiuio
    inst_libdir_file 'libgcc_s.so*'
    inst_multiple umount iscsi-iname iscsiadm iscsid
    inst_binary sort

    inst_multiple -o \
        "$systemdsystemunitdir"/iscsid.socket \
        "$systemdsystemunitdir"/iscsid.service \
        "$systemdsystemunitdir"/iscsiuio.service \
        "$systemdsystemunitdir"/iscsiuio.socket \
        "$systemdsystemunitdir"/sockets.target.wants/iscsid.socket \
        "$systemdsystemunitdir"/sockets.target.wants/iscsiuio.socket

    if [[ $hostonly ]]; then
        local -a _filenames

        inst_dir /etc/iscsi
        mapfile -t -d '' _filenames < <(find /etc/iscsi -type f -print0)
        inst_multiple "${_filenames[@]}"
    else
        inst_simple /etc/iscsi/iscsid.conf
    fi

    # Detect iBFT and perform mandatory steps
    if [[ $hostonly_cmdline == "yes" ]]; then
        local _iscsiconf
        _iscsiconf=$(cmdline)
        [[ $_iscsiconf ]] && printf "%s\n" "$_iscsiconf" >> "${initdir}/etc/cmdline.d/95iscsi.conf"
    fi

    inst_hook cmdline 90 "$moddir/parse-iscsiroot.sh"
    inst_hook cleanup 90 "$moddir/cleanup-iscsi.sh"
    inst "$moddir/iscsiroot.sh" "/sbin/iscsiroot"

    if ! dracut_module_included "systemd"; then
        inst "$moddir/mount-lun.sh" "/bin/mount-lun.sh"
    else
        inst_multiple -o \
            "$systemdsystemunitdir"/iscsi.service \
            "$systemdsystemunitdir"/iscsi-init.service \
            "$systemdsystemunitdir"/iscsid.service \
            "$systemdsystemunitdir"/iscsid.socket \
            "$systemdsystemunitdir"/iscsiuio.service \
            "$systemdsystemunitdir"/iscsiuio.socket \
            iscsiadm iscsid

        for i in \
            iscsid.socket \
            iscsiuio.socket; do
            $SYSTEMCTL -q --root "$initdir" enable "$i"
        done

        mkdir -p "${initdir}/$systemdsystemunitdir/iscsid.service.d"
        {
            echo "[Unit]"
            echo "DefaultDependencies=no"
            echo "Conflicts=shutdown.target"
            echo "Before=shutdown.target"
        } > "${initdir}/$systemdsystemunitdir/iscsid.service.d/dracut.conf"

        mkdir -p "${initdir}/$systemdsystemunitdir/iscsid.socket.d"
        {
            echo "[Unit]"
            echo "DefaultDependencies=no"
            echo "Conflicts=shutdown.target"
            echo "Before=shutdown.target sockets.target"
        } > "${initdir}/$systemdsystemunitdir/iscsid.socket.d/dracut.conf"

        mkdir -p "${initdir}/$systemdsystemunitdir/iscsiuio.service.d"
        {
            echo "[Unit]"
            echo "DefaultDependencies=no"
            echo "Conflicts=shutdown.target"
            echo "Before=shutdown.target"
        } > "${initdir}/$systemdsystemunitdir/iscsiuio.service.d/dracut.conf"

        mkdir -p "${initdir}/$systemdsystemunitdir/iscsiuio.socket.d"
        {
            echo "[Unit]"
            echo "DefaultDependencies=no"
            echo "Conflicts=shutdown.target"
            echo "Before=shutdown.target sockets.target"
        } > "${initdir}/$systemdsystemunitdir/iscsiuio.socket.d/dracut.conf"

        # Fedora 34 iscsid requires iscsi-shutdown.service
        # which would terminate all iSCSI connections on switch root
        cat > "${initdir}/$systemdsystemunitdir/iscsi-shutdown.service" << EOF
[Unit]
Description=Dummy iscsi-shutdown.service for the initrd
Documentation=man:iscsid(8) man:iscsiadm(8)
DefaultDependencies=no
Conflicts=shutdown.target
After=systemd-remount-fs.service network.target iscsid.service iscsiuio.service
Before=remote-fs-pre.target

[Service]
Type=oneshot
RemainAfterExit=false
ExecStart=-/usr/bin/true
EOF
    fi
    inst_dir /var/lib/iscsi
    mkdir -p "${initdir}/var/lib/iscsi/nodes"
    # Fedora 34 iscsid wants a non-empty /var/lib/iscsi/nodes directory
    : > "${initdir}/var/lib/iscsi/nodes/.dracut"
    dracut_need_initqueue
}
