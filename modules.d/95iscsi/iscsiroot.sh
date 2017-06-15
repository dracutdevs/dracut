#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# This implementation is incomplete: Discovery mode is not implemented and
# the argument handling doesn't follow currently agreed formats. This is mainly
# because rfc4173 does not say anything about iscsi_initiator but open-iscsi's
# iscsistart needs this.
#

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type parse_iscsi_root >/dev/null 2>&1 || . /lib/net-lib.sh
type write_fs_tab >/dev/null 2>&1 || . /lib/fs-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# Huh? Empty $1?
[ -z "$1" ] && exit 1

# Huh? Empty $2?
[ -z "$2" ] && exit 1

# Huh? Empty $3? This isn't really necessary, since NEWROOT isn't
# used here. But let's be consistent
[ -z "$3" ] && exit 1

# root is in the form root=iscsi:[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
netif="$1"
iroot="$2"

# If it's not iscsi we don't continue
[ "${iroot%%:*}" = "iscsi" ] || exit 1

iroot=${iroot#iscsi}
iroot=${iroot#:}

# XXX modprobe crc32c should go in the cmdline parser, but I haven't yet
# figured out a way how to check whether this is built-in or not
modprobe crc32c 2>/dev/null

if [ -z "${DRACUT_SYSTEMD}" ] && [ -e /sys/module/bnx2i ] && ! [ -e /tmp/iscsiuio-started ]; then
        iscsiuio
        > /tmp/iscsiuio-started
fi

handle_firmware()
{
    if ! iscsistart -f; then
        warn "iscistart: Could not get list of targets from firmware."
        return 1
    fi

    for p in $(getargs rd.iscsi.param -d iscsi_param); do
	iscsi_param="$iscsi_param --param $p"
    done

    if ! iscsistart -b $iscsi_param; then
        warn "'iscsistart -b $iscsi_param' failed with return code $?"
    fi

    echo 'started' > "/tmp/iscsistarted-iscsi:"
    echo 'started' > "/tmp/iscsistarted-firmware"

    need_shutdown
    return 0
}


handle_netroot()
{
    local iscsi_initiator iscsi_target_name iscsi_target_ip iscsi_target_port
    local iscsi_target_group iscsi_protocol iscsirw iscsi_lun
    local iscsi_username iscsi_password
    local iscsi_in_username iscsi_in_password
    local iscsi_iface_name iscsi_netdev_name
    local iscsi_param
    local p

    # override conf settings by command line options
    arg=$(getargs rd.iscsi.initiator -d iscsi_initiator=)
    [ -n "$arg" ] && iscsi_initiator="$arg"
    arg=$(getargs rd.iscsi.target.name -d iscsi_target_name=)
    [ -n "$arg" ] && iscsi_target_name="$arg"
    arg=$(getargs rd.iscsi.target.ip -d iscsi_target_ip)
    [ -n "$arg" ] && iscsi_target_ip="$arg"
    arg=$(getargs rd.iscsi.target.port -d iscsi_target_port=)
    [ -n "$arg" ] && iscsi_target_port="$arg"
    arg=$(getargs rd.iscsi.target.group -d iscsi_target_group=)
    [ -n "$arg" ] && iscsi_target_group="$arg"
    arg=$(getargs rd.iscsi.username -d iscsi_username=)
    [ -n "$arg" ] && iscsi_username="$arg"
    arg=$(getargs rd.iscsi.password -d iscsi_password)
    [ -n "$arg" ] && iscsi_password="$arg"
    arg=$(getargs rd.iscsi.in.username -d iscsi_in_username=)
    [ -n "$arg" ] && iscsi_in_username="$arg"
    arg=$(getargs rd.iscsi.in.password -d iscsi_in_password=)
    [ -n "$arg" ] && iscsi_in_password="$arg"
    for p in $(getargs rd.iscsi.param -d iscsi_param); do
	iscsi_param="$iscsi_param --param $p"
    done

    parse_iscsi_root "$1" || return 1

    # Bail out early, if there is no route to the destination
    if is_ip "$iscsi_target_ip" && [ "$netif" != "timeout" ] && ! all_ifaces_setup && getargbool 1 rd.iscsi.testroute; then
        ip route get "$iscsi_target_ip" >/dev/null 2>&1 || return 0
    fi

# XXX is this needed?
    getarg ro && iscsirw=ro
    getarg rw && iscsirw=rw
    fsopts="${fsopts:+$fsopts,}${iscsirw}"

    if [ -z "$iscsi_initiator" ] && [ -f /sys/firmware/ibft/initiator/initiator-name ] && ! [ -f /tmp/iscsi_set_initiator ]; then
           iscsi_initiator=$(while read line || [ -n "$line" ]; do echo $line;done < /sys/firmware/ibft/initiator/initiator-name)
           echo "InitiatorName=$iscsi_initiator" > /run/initiatorname.iscsi
           rm -f /etc/iscsi/initiatorname.iscsi
           mkdir -p /etc/iscsi
           ln -fs /run/initiatorname.iscsi /etc/iscsi/initiatorname.iscsi
           systemctl restart iscsid
           sleep 1
           > /tmp/iscsi_set_initiator
    fi

    if [ -z "$iscsi_initiator" ]; then
        [ -f /run/initiatorname.iscsi ] && . /run/initiatorname.iscsi
        [ -f /etc/initiatorname.iscsi ] && . /etc/initiatorname.iscsi
        [ -f /etc/iscsi/initiatorname.iscsi ] && . /etc/iscsi/initiatorname.iscsi
        iscsi_initiator=$InitiatorName
    fi

    if [ -z "$iscsi_initiator" ]; then
        iscsi_initiator=$(iscsi-iname)
        echo "InitiatorName=$iscsi_initiator" > /run/initiatorname.iscsi
        rm -f /etc/iscsi/initiatorname.iscsi
        mkdir -p /etc/iscsi
        ln -fs /run/initiatorname.iscsi /etc/iscsi/initiatorname.iscsi
        systemctl restart iscsid
        > /tmp/iscsi_set_initiator
        # FIXME: iscsid is not yet ready, when the service is :-/
        sleep 1
    fi


    if [ -z $iscsi_target_port ]; then
        iscsi_target_port=3260
    fi

    if [ -z $iscsi_target_group ]; then
        iscsi_target_group=1
    fi

    if [ -z $iscsi_lun ]; then
        iscsi_lun=0
    fi

    echo "InitiatorName=$iscsi_initiator" > /run/initiatorname.iscsi
    ln -fs /run/initiatorname.iscsi /dev/.initiatorname.iscsi
    if ! [ -e /etc/iscsi/initiatorname.iscsi ]; then
        mkdir -p /etc/iscsi
        ln -fs /run/initiatorname.iscsi /etc/iscsi/initiatorname.iscsi
    fi
# FIXME $iscsi_protocol??

    if [ "$root" = "dhcp" ] || [ "$netroot" = "dhcp" ]; then
        # if root is not specified try to mount the whole iSCSI LUN
        printf 'SYMLINK=="disk/by-path/*-iscsi-*-%s", SYMLINK+="root"\n' "$iscsi_lun" >> /etc/udev/rules.d/99-iscsi-root.rules
        udevadm control --reload
        write_fs_tab /dev/root
        wait_for_dev -n /dev/root

        # install mount script
        [ -z "$DRACUT_SYSTEMD" ] && \
            echo "iscsi_lun=$iscsi_lun . /bin/mount-lun.sh " > $hookdir/mount/01-$$-iscsi.sh
    fi

    if [ -n "$DRACUT_SYSTEMD" ] && command -v systemd-run >/dev/null 2>&1; then
        netroot_enc=$(systemd-escape "iscsistart_${1}")
        status=$(systemctl is-active "$netroot_enc" 2>/dev/null)
        is_active=$?
        if [ $is_active -ne 0 ]; then
            if [ "$status" != "activating" ] && ! systemctl is-failed "$netroot_enc" >/dev/null 2>&1; then
                systemd-run --service-type=oneshot --remain-after-exit --quiet \
                            --description="Login iSCSI Target $iscsi_target_name" \
                            -p 'DefaultDependencies=no' \
                            --unit="$netroot_enc" -- \
                            $(command -v iscsistart) \
                            -i "$iscsi_initiator" -t "$iscsi_target_name"        \
                            -g "$iscsi_target_group" -a "$iscsi_target_ip"      \
                            -p "$iscsi_target_port" \
                            ${iscsi_username:+-u "$iscsi_username"} \
                            ${iscsi_password:+-w "$iscsi_password"} \
                            ${iscsi_in_username:+-U "$iscsi_in_username"} \
                            ${iscsi_in_password:+-W "$iscsi_in_password"} \
	                    ${iscsi_iface_name:+--param "iface.iscsi_ifacename=$iscsi_iface_name"} \
	                    ${iscsi_netdev_name:+--param "iface.net_ifacename=$iscsi_netdev_name"} \
                            ${iscsi_param} >/dev/null 2>&1 \
	            && { > $hookdir/initqueue/work ; }
            else
                systemctl --no-block restart "$netroot_enc" >/dev/null 2>&1 \
	            && { > $hookdir/initqueue/work ; }
            fi
        fi
    else
        iscsistart -i "$iscsi_initiator" -t "$iscsi_target_name"        \
                   -g "$iscsi_target_group" -a "$iscsi_target_ip"      \
                   -p "$iscsi_target_port" \
                   ${iscsi_username:+-u "$iscsi_username"} \
                   ${iscsi_password:+-w "$iscsi_password"} \
                   ${iscsi_in_username:+-U "$iscsi_in_username"} \
                   ${iscsi_in_password:+-W "$iscsi_in_password"} \
	           ${iscsi_iface_name:+--param "iface.iscsi_ifacename=$iscsi_iface_name"} \
	           ${iscsi_netdev_name:+--param "iface.net_ifacename=$iscsi_netdev_name"} \
                   ${iscsi_param} \
	    && { > $hookdir/initqueue/work ; }
    fi
    netroot_enc=$(str_replace "$1" '/' '\2f')
    echo 'started' > "/tmp/iscsistarted-iscsi:${netroot_enc}"
    return 0
}

ret=0

if [ "$netif" != "timeout" ] && getargbool 1 rd.iscsi.waitnet; then
    all_ifaces_setup || exit 0
fi

if [ "$netif" = "timeout" ] && all_ifaces_setup; then
    # s.th. went wrong and the timeout script hits
    # restart
    systemctl restart iscsid
    # damn iscsid is not ready after unit says it's ready
    sleep 2
fi

if getargbool 0 rd.iscsi.firmware -d -y iscsi_firmware ; then
    if [ "$netif" = "timeout" ] || [ "$netif" = "online" ]; then
        handle_firmware
        ret=$?
    fi
fi

if ! [ "$netif" = "online" ]; then
    # loop over all netroot parameter
    if nroot=$(getarg netroot) && [ "$nroot" != "dhcp" ]; then
        for nroot in $(getargs netroot); do
            [ "${nroot%%:*}" = "iscsi" ] || continue
            nroot="${nroot##iscsi:}"
            if [ -n "$nroot" ]; then
                handle_netroot "$nroot"
                ret=$(($ret + $?))
            fi
        done
    else
        if [ -n "$iroot" ]; then
            handle_netroot "$iroot"
            ret=$?
        fi
    fi
fi

need_shutdown

# now we have a root filesystem somewhere in /dev/sd*
# let the normal block handler handle root=
exit $ret
