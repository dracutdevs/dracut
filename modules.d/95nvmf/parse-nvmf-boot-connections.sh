#!/bin/sh
#
# Supported formats:
# nvmf.hostnqn=<hostnqn>
# nvmf.hostid=<hostid>
# nvmf.discover=<transport>:<traddr>:<host-traddr>:<trsvcid>
#
# Examples:
# nvmf.hostnqn=nqn.2014-08.org.nvmexpress:uuid:37303738-3034-584d-5137-333230423843
# nvmf.discover=rdma:192.168.1.3::4420
# nvmf.discover=tcp:192.168.1.3::4420
# nvmf.discover=tcp:192.168.1.3
# nvmf.discover=fc:auto
#
# Note: FC does autodiscovery, so typically there is no need to
# specify any discover parameters for FC.
#

type is_ip >/dev/null 2>&1 || . /lib/net-lib.sh

if getargbool 0 rd.nonvmf ; then
    warn "rd.nonvmf=0: skipping nvmf"
    return 0
fi

initqueue --onetime modprobe --all -b -q nvme nvme_tcp nvme_core nvme_fabrics

traddr="none"
trtype="none"
hosttraddr="none"
trsvcid=4420

validate_ip_conn() {
    if ! getargbool 0 rd.neednet ; then
        warn "$trtype transport requires rd.neednet=1"
        return 1
    fi

    local_address=$(ip -o route get to $traddr | sed -n 's/.*src \([0-9a-f.:]*\).*/\1/p')

    # confirm we got a local IP address
    if ! is_ip "$local_address" ; then
        warn "$traddr is an invalid address";
        return 1
    fi

    ifname=$(ip -o route get to $local_address | sed -n 's/.*dev \([^ ]*\).*/\1/p')

    if ip l show "$ifname" >/dev/null 2>&1 ; then
       warn "invalid network interface $ifname"
       return 1
    fi

    # confirm there's a route to destination
    if ip route get "$traddr" >/dev/null 2>&1 ; then
        warn "no route to $traddr"
        return 1
    fi
}

parse_nvmf_discover() {
    OLDIFS="$IFS"
    IFS=:
    set $1
    IFS="$OLDIFS"

    case $# in
        2)
            [ -n "$1" ] && trtype=$1
            [ -n "$2" ] && traddr=$2
            ;;
        3)
            [ -n "$1" ] && trtype=$1
            [ -n "$2" ] && traddr=$2
            [ -n "$3" ] && hosttraddr=$3
            ;;
        4)
            [ -n "$1" ] && trtype=$1
            [ -n "$2" ] && traddr=$2
            [ -n "$3" ] && hosttraddr=$3
            [ -n "$4" ] && trsvcid=$4
            ;;
        *)
            warn "Invalid arguments for nvmf.discover=$1"
            return 1
            ;;
    esac
    if [ "$traddr" = "none" ] ; then
        warn "traddr is mandatory for $trtype"
        return 1;
    fi
    if [ "$trtype" = "fc" ] ; then
        if [ "$hosttraddr" = "none" ] ; then
            warn "host traddr is mandatory for fc"
            return 1
        fi
    elif [ "$trtype" != "rdma" ] && [ "$trtype" != "tcp" ] ; then
        warn "unsupported transport $trtype"
        return 1
    fi
    if [ "$trtype" = "tcp" ]; then
        validate_ip_conn
    fi
    echo "--transport=$trtype --traddr=$traddr --host-traddr=$hosttraddr --trsvcid=$trsvcid" >> /etc/nvme/discovery.conf
}

nvmf_hostnqn=$(getarg nvmf.hostnqn=)
if [ -n "$nvmf_hostnqn" ] ; then
    echo "$nvmf_hostnqn" > /etc/nvme/hostnqn
fi
nvmf_hostid=$(getarg nvmf.hostid=)
if [ -n "$nvmf_hostid" ] ; then
    echo "$nvmf_hostid" > /etc/nvme/hostid
fi

for d in $(getargs nvmf.discover=); do
    parse_nvmf_discover "$d"
done

# Host NQN and host id are mandatory for NVMe-oF
[ -f "/etc/nvme/hostnqn" ] || exit 0
[ -f "/etc/nvme/hostid" ] || exit 0

if [ -f "/etc/nvme/discovery.conf" ] ; then
    if [ "$trtype" = "tcp" ] ; then
        /sbin/initqueue --settled --onetime --unique --name nvme-discover /usr/sbin/nvme connect-all
        > /tmp/net.$ifname.did-setup
    else
        /sbin/initqueue --onetime --unique --name nvme-discover /usr/sbin/nvme connect-all
    fi
else
    if [ "$trtype" = "tcp" ] ; then
        /sbin/initqueue --settled --onetime --unique /usr/sbin/nvme connect-all -t tcp -a $traddr -s $trsvcid
        > /tmp/net.$ifname.did-setup
    else
        /sbin/initqueue --finished --unique --name nvme-fc-autoconnect echo 1 > /sys/class/fc/fc_udev_device/nvme_discovery
    fi
fi
