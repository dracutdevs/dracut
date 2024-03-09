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

command -v getarg > /dev/null || . /lib/dracut-lib.sh
command -v is_ip > /dev/null || . /lib/net-lib.sh

## Sample NBFT output from nvme show-nbft -H -s -d -o json
# [
#   {
#     "filename":"/sys/firmware/acpi/tables/NBFT",
#     "host":{
#       "nqn":"nqn.2014-08.org.nvmexpress:uuid:d6f07002-7eb5-4841-a185-400e296afae4",
#       "id":"111919da-21ea-cc4e-bafe-216d8372dd31",
#       "host_id_configured":0,
#       "host_nqn_configured":0,
#       "primary_admin_host_flag":"not indicated"
#     },
#     "subsystem":[
#       {
#         "index":1,
#         "num_hfis":1,
#         "hfis":[
#           1
#         ],
#         "transport":"tcp",
#         "transport_address":"192.168.100.216",
#         "transport_svcid":"4420",
#         "subsys_port_id":0,
#         "nsid":1,
#         "nid_type":"uuid",
#         "nid":"424d1c8a-8ef9-4681-b2fc-8c343bd8fa69",
#         "subsys_nqn":"timberland-01",
#         "controller_id":0,
#         "asqsz":0,
#         "pdu_header_digest_required":0,
#         "data_digest_required":0
#       }
#     ],
#     "hfi":[
#       {
#         "index":1,
#         "transport":"tcp",
#         "pcidev":"0:0:2.0",
#         "mac_addr":"52:54:00:4f:97:e9",
#         "vlan":0,
#         "ip_origin":63,
#         "ipaddr":"192.168.100.217",
#         "subnet_mask_prefix":24,
#         "gateway_ipaddr":"0.0.0.0",
#         "route_metric":0,
#         "primary_dns_ipaddr":"0.0.0.0",
#         "secondary_dns_ipaddr":"0.0.0.0",
#         "dhcp_server_ipaddr":"",
#         "this_hfi_is_default_route":1
#       }
#     ],
#     "discovery":[
#     ]
#   }
# ]
#
# If the IP address is derived from DHCP, it sets the field
# "hfi.dhcp_server_ipaddr" to a non-emtpy value.
#
#

nbft_run_jq() {
    local st
    local opts="-e"

    while [ $# -gt 0 ]; do
        case $1 in
            -*)
                opts="$opts $1"
                ;;
            *)
                break
                ;;
        esac
        shift
    done
    # Not quoting is intentional here. We won't get glob expressions passed.
    # shellcheck disable=SC2086
    jq $opts "$1" << EOF
$2
EOF
    st=$?
    if [ $st -ne 0 ]; then
        warn "NBFT: jq error while processing \"$1\""
        return $st
    else
        return 0
    fi
}

nbft_check_empty_address() {
    # suppress meaningless or empty IP addresses
    # "null" is returned by jq if no match found for expression
    case $1 in
        null | "::" | "0.0.0.0") ;;
        *)
            echo "$1"
            ;;
    esac
}

nbft_parse_hfi() {
    # false positive of shellcheck - no expansion in variable assignments
    # shellcheck disable=2086
    local hfi_json=$1
    local mac iface ipaddr prefix vlan gateway dns1 dns2 hostname adrfam dhcp

    mac=$(nbft_run_jq -r .mac_addr "$hfi_json") || return 1
    iface=$(set_ifname nbft "$mac")

    vlan=$(nbft_run_jq .vlan "$hfi_json") || vlan=0
    # treat VLAN zero as "no vlan"
    [ "$vlan" -ne 0 ] || vlan=

    [ ! -e /tmp/net."${iface}${vlan:+.$vlan}".has_ibft_config ] || return 0

    dhcp=$(nbft_run_jq -r .dhcp_server_ipaddr "$hfi_json")
    # We need to check $? here as the above is an assignment
    # shellcheck disable=2181
    if [ $? -eq 0 ] && [ "$dhcp" ] && [ "$dhcp" != null ]; then
        case $dhcp in
            *:*)
                echo ip="$iface${vlan:+.$vlan}:dhcp6"
                ;;
            *.*.*.*)
                echo ip="$iface${vlan:+.$vlan}:dhcp"
                ;;
            *)
                warn "Invalid value for dhcp_server_ipaddr: $dhcp"
                return 1
                ;;
        esac
    else
        ipaddr=$(nbft_run_jq -r .ipaddr "$hfi_json") || return 1

        case $ipaddr in
            *.*.*.*)
                adrfam=ipv4
                ;;
            *:*)
                adrfam=ipv6
                ;;
            *)
                warn "invalid address: $ipaddr"
                return 1
                ;;
        esac
        prefix=$(nbft_run_jq -r .subnet_mask_prefix "$hfi_json")
        # Need to check $? here as he above is an assignment
        # shellcheck disable=2181
        if [ $? -ne 0 ] && [ "$adrfam" = ipv6 ]; then
            prefix=128
        fi
        # Use brackets for IPv6
        if [ "$adrfam" = ipv6 ]; then
            ipaddr="[$ipaddr]"
        fi

        gateway=$(nbft_check_empty_address \
            "$(nbft_run_jq -r .gateway_ipaddr "$hfi_json")")
        dns1=$(nbft_check_empty_address \
            "$(nbft_run_jq -r .primary_dns_ipaddr "$hfi_json")")
        dns2=$(nbft_check_empty_address \
            "$(nbft_run_jq -r .secondary_dns_ipaddr "$hfi_json")")
        hostname=$(nbft_run_jq -r .host_name "$hfi_json" 2> /dev/null) || hostname=

        echo "ip=$ipaddr::$gateway:$prefix:$hostname:$iface${vlan:+.$vlan}:none${dns1:+:$dns1}${dns2:+:$dns2}"
    fi

    if [ "$vlan" ]; then
        echo "vlan=$iface.$vlan:$iface"
        echo "$mac" > "/tmp/net.$iface.$vlan.has_ibft_config"
    else
        echo "$mac" > "/tmp/net.$iface.has_ibft_config"
    fi
    : > /tmp/valid_nbft_entry_found
}

nbft_parse() {
    local nbft_json n_nbft all_hfi_json n_hfi
    local j=0 i

    nbft_json=$(nvme nbft show -H -o json) || return 0
    n_nbft=$(nbft_run_jq ". | length" "$nbft_json") || return 0

    while [ "$j" -lt "$n_nbft" ]; do
        all_hfi_json=$(nbft_run_jq ".[$j].hfi" "$nbft_json") || continue
        n_hfi=$(nbft_run_jq ". | length" "$all_hfi_json") || continue
        i=0

        while [ "$i" -lt "$n_hfi" ]; do
            nbft_parse_hfi "$(nbft_run_jq ".[$i]" "$all_hfi_json")"
            i=$((i + 1))
        done
        j=$((j + 1))
    done >> /etc/cmdline.d/40-nbft.conf
}

if getargbool 0 rd.nonvmf; then
    warn "rd.nonvmf=0: skipping nvmf"
    return 0
fi

if getargbool 0 rd.nvmf.nostatic; then
    rm -f /etc/cmdline.d/95nvmf-args.conf
    rm -f /etc/nvme/discovery.conf /etc/nvme/config.json
fi

if ! getargbool 0 rd.nvmf.nonbft; then
    for _x in /sys/firmware/acpi/tables/NBFT*; do
        if [ -f "$_x" ]; then
            nbft_parse
            break
        fi
    done
fi

initqueue --onetime modprobe -b -q nvme_tcp
initqueue --onetime modprobe -b -q nvme_core
initqueue --onetime modprobe -b -q nvme_fabrics

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
    if [ "$trtype" = "tcp" ]; then
        : > /tmp/nvmf_needs_network
    elif [ "$trtype" = "fc" ]; then
        if [ "$traddr" = "auto" ]; then
            rm -f /etc/nvme/discovery.conf /etc/nvme/config.json
            return 1
        fi
        if [ "$hosttraddr" = "none" ]; then
            warn "host traddr is mandatory for fc"
            return 0
        fi
    elif [ "$trtype" != "rdma" ]; then
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

rm -f /tmp/nvmf-fc-auto
for d in $(getargs rd.nvmf.discover -d nvmf.discover=); do
    parse_nvmf_discover "$d" || {
        : > /tmp/nvmf-fc-auto
        break
    }
done

if [ -e /tmp/nvmf_needs_network ] || [ -e /tmp/valid_nbft_entry_found ]; then
    echo "rd.neednet=1" > /etc/cmdline.d/nvmf-neednet.conf
    # netroot is a global variable that is present in all "sourced" scripts
    # shellcheck disable=SC2034
    netroot=nbft
    rm -f /tmp/nvmf_needs_network
fi

/sbin/initqueue --settled --onetime --name nvmf-connect-settled /sbin/nvmf-autoconnect.sh settled
/sbin/initqueue --timeout --onetime --name nvmf-connect-timeout /sbin/nvmf-autoconnect.sh timeout
