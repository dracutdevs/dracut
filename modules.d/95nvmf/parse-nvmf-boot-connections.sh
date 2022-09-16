#!/bin/sh
#
# Supported formats:
# rd.nvmf.hostnqn=<hostnqn>
# rd.nvmf.hostid=<hostid>
# rd.nvmf.discover=<transport>,<traddr>,<host-traddr>,<trsvcid>
#
# Examples:
# rd.nvmf.hostnqn=nqn.2014-08.org.nvmexpress:uuid:37303738-3034-584d-5137-333230423843
# rd.nvmf.discover=rdma,192.168.1.3,,4420
# rd.nvmf.discover=tcp,192.168.1.3,,4420
# rd.nvmf.discover=tcp,192.168.1.3
# rd.nvmf.discover=fc,nn-0x200400a098d85236:pn-0x201400a098d85236,nn-0x200000109b7db455:pn-0x100000109b7db455
# rd.nvmf.discover=fc,auto
#
# Note: FC does autodiscovery, so typically there is no need to
# specify any discover parameters for FC.
#

type is_ip > /dev/null 2>&1 || . /lib/net-lib.sh

if getargbool 0 rd.nonvmf; then
    warn "rd.nonvmf=0: skipping nvmf"
    return 0
fi

initqueue --onetime modprobe --all -b -q nvme_tcp nvme_core nvme_fabrics

parse_nvmf_discover() {
    traddr="none"
    trtype="none"
    hosttraddr="none"
    trsvcid=4420
    OLDIFS="$IFS"
    IFS=,
    # shellcheck disable=SC2086
    set -- $1
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
            warn "Invalid arguments for rd.nvmf.discover=$1"
            return 0
            ;;
    esac
    if [ "$traddr" = "none" ]; then
        warn "traddr is mandatory for $trtype"
        return 0
    fi
    if [ "$trtype" = "fc" ]; then
        if [ "$traddr" = "auto" ]; then
            rm /etc/nvme/discovery.conf
            return 1
        fi
        if [ "$hosttraddr" = "none" ]; then
            warn "host traddr is mandatory for fc"
            return 0
        fi
    elif [ "$trtype" != "rdma" ] && [ "$trtype" != "tcp" ]; then
        warn "unsupported transport $trtype"
        return 0
    fi
    if [ "$trtype" = "fc" ]; then
        echo "--transport=$trtype --traddr=$traddr --host-traddr=$hosttraddr" >> /etc/nvme/discovery.conf
    else
        echo "--transport=$trtype --traddr=$traddr --host-traddr=$hosttraddr --trsvcid=$trsvcid" >> /etc/nvme/discovery.conf
    fi
    return 0
}

nvmf_hostnqn=$(getarg rd.nvmf.hostnqn -d nvmf.hostnqn=)
if [ -n "$nvmf_hostnqn" ]; then
    echo "$nvmf_hostnqn" > /etc/nvme/hostnqn
fi
nvmf_hostid=$(getarg rd.nvmf.hostid -d nvmf.hostid=)
if [ -n "$nvmf_hostid" ]; then
    echo "$nvmf_hostid" > /etc/nvme/hostid
fi

for d in $(getargs rd.nvmf.discover -d nvmf.discover=); do
    parse_nvmf_discover "$d" || break
done

# Host NQN and host id are mandatory for NVMe-oF
[ -f "/etc/nvme/hostnqn" ] || exit 0
[ -f "/etc/nvme/hostid" ] || exit 0

if [ -f "/etc/nvme/discovery.conf" ]; then
    /sbin/initqueue --settled --onetime --unique --name nvme-discover /usr/sbin/nvme connect-all
else
    # No nvme command line arguments present, try autodiscovery
    if [ "$trtype" = "fc" ]; then
        /sbin/initqueue --finished --onetime --unique --name nvme-fc-autoconnect /sbin/nvmf-autoconnect.sh
    fi
fi
