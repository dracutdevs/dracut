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
# nvme.discover=tcp:192.168.1.3::4420
# nvme.discover=tcp:192.168.1.3
# nvmf.discover=fc:auto
#
# Note: FC does autodiscovery, so typically there is no need to
# specify any discover parameters for FC.
#

if getargbool 0 rd.nonvmf ; then
    warn "rd.nonvmf=0: skipping nvmf"
    return 0
fi

initqueue --onetime modprobe --all -b -q nvme nvme_tcp nvme_core nvme_fabrics

traddr="none"
trtype="none"
hosttraddr="none"
trsvcid=4420

parse_nvmf_discover() {
    OLDIFS="$IFS"
    IFS=:
    set $1
    IFS="$OLDIFS"

    case $# in
        2)
            [ ! -z "$1" ] && trtype=$1
            [ ! -z "$2" ] && traddr=$2
            ;;
        3)
            [ ! -z "$1" ] && trtype=$1
            [ ! -z "$2" ] && traddr=$2
            [ ! -z "$3" ] && hosttraddr=$3
            ;;
        4)
            [ ! -z "$1" ] && trtype=$1
            [ ! -z "$2" ] && traddr=$2
            [ ! -z "$3" ] && hosttraddr=$3
            [ ! -z "$4" ] && trsvcid=$4
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
    if [ "$trtype" = "tcp" ] ; then
        if ! getargbool 0 rd.neednet ; then
            warn "$trtype transport requires rd.neednet=1"
            return 1
        fi
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
        echo "exit 0" > /tmp/net.nvmf.did-setup # hack to fool rd.neednet=1, FIXME
    else
        /sbin/initqueue --onetime --unique --name nvme-discover /usr/sbin/nvme connect-all
    fi
else
    if [ "$trtype" = "tcp" ] ; then
        /sbin/initqueue --settled --onetime --unique /usr/sbin/nvme connect-all -t tcp -a $traddr -s $trsvcid
        echo "exit 0" > /tmp/net.nvmf.did-setup # hack to fool rd.neednet=1, FIXME
    else
        /sbin/initqueue --finished --unique --name nvme-fc-autoconnect echo 1 > /sys/class/fc/fc_udev_device/nvme_discovery
    fi
fi
