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
# nvmf.discover=fc:auto
#
# Note: FC does autodiscovery, so typically there is no need to
# specify any discover parameters for FC.
#

parse_nvmf_discover() {
    OLDIFS="$IFS"
    IFS=:
    trtype="none"
    traddr="none"
    hosttraddr="none"
    trsvcid=4420

    set $1
    IFS="$OLDIFS"

    case $# in
        2)
            trtype=$1
            traddr=$2
            ;;
        3)
            trtype=$1
            traddr=$2
            hosttraddr=$3
            ;;
        4)
            trtype=$1
            traddr=$2
            hosttraddr=$3
            trsvcid=$4
            ;;
        *)
            warn "Invalid arguments for nvmf.discover=$1"
            return 1
            ;;
    esac
    if [ -z "$traddr" ] ; then
        warn "traddr is mandatory for $trtype"
        return 1;
    fi
    [ -z "$hosttraddr" ] && hosttraddr="none"
    [ -z "$trsvcid" ] && trsvcid="none"
    if [ "$trtype" = "fc" ] ; then
        if [ -z "$hosttraddr" ] ; then
            warn "host traddr is mandatory for fc"
            return 1
        fi
    elif [ "$trtype" != "rdma" ] && [ "$trtype" != "tcp" ] ; then
        warn "unsupported transport $trtype"
        return 1
    elif [ -z "$trsvcid" ] ; then
        trsvcid=4420
    fi
    echo "--transport=$trtype --traddr=$traddr --host-traddr=$hosttraddr --trsvcid=$trsvcid" >> /etc/nvme/discovery.conf
}

if ! getargbool 0 rd.nonvmf ; then
	info "rd.nonvmf=0: skipping nvmf"
	return 0
fi

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
    /sbin/initqueue --onetime --unique --name nvme-discover /usr/sbin/nvme connect-all
else
    /sbin/initqueue --finished --unique --name nvme-fc-autoconnect echo 1 > /sys/class/fc/fc_udev_device/nvme_discovery
fi
