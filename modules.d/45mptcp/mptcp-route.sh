#!/bin/sh

IP="/bin/ip"

if [ -e /tmp/mptcp.info ]; then
    . /tmp/mptcp.info
fi

prepare_rt_table() {
        local rttables=/etc/iproute2/rt_tables
        local iface=$1
        [[ "${iface}" = 'lo' ]] && return
        if ! egrep -q "\s${iface}\s*"\$ $rttables; then
                idx=$(wc -l <$rttables)
                echo -e "$(( 300 + ${idx} ))\t${iface}" >> $rttables
        fi
}

get_ipv4_addressses() {
        local iface=$1
        $IP -4 addr show dev ${iface} | sed -rn '/inet / s_^.*inet ([0-9.]*)/.*$_\1_p'
}

get_ipv6_addressses() {
        local iface=$1
        $IP -6 addr show dev ${iface} | sed -rn '/inet6 / s_^.*inet6 ([0-9a-f:]*)/.*$_\1_p'
}

transfer_routes_ipv4() {
        local iface=$1
        $IP -4 route flush table ${iface}
        while read line; do
                [[ -z "$line" ]] && continue
                $IP -4 route add ${line} table ${iface}
        done <<-EOF
        $($IP -4 rou show table main | grep "dev ${iface}" |\
                sed -r 's_expires [^ ]*__' | sed -r 's_proto [^ ]*__' )
        EOF
}

transfer_routes_ipv6() {
        local iface=$1
        $IP -6 route flush table ${iface}
        while read line; do
                [[ -z "$line" ]] && continue
                $IP -6 route add ${line} table ${iface}
        done <<-EOF
        $($IP -6 rou show table main | grep "dev ${iface}" |\
                sed -r 's_expires [^ ]*__' | sed -r 's_proto [^ ]*__' )
        EOF
}

get_table_id() {
        local rttables=/etc/iproute2/rt_tables
        local table=$1
        sed -rn "/^\s*[0-9]*\s*${table}/ s_^\s*([0-9]+)\s.*_\1_p" $rttables
}

replace_rules_ipv4() {
        local iface=$1
        local tableid=$(get_table_id $iface)
        while $IP -4 rule show | egrep -q ^${tableid}; do
                $IP -4 rule del prio ${tableid}
        done
        for ipaddr in $(get_ipv4_addressses ${iface}); do
                $IP -4 rule add prio ${tableid} from ${ipaddr} table ${iface}
        done
}

replace_rules_ipv6() {
        local iface=$1
        local tableid=$(get_table_id $iface)
        while $IP -6 rule show | egrep -q ^${tableid}; do
                $IP -6 rule del prio ${tableid}
        done
        for ipaddr in $(get_ipv6_addressses ${iface}); do
                echo $ipaddr | egrep -q '^fe80:' && continue
                $IP -6 rule add prio ${tableid} from ${ipaddr} table ${iface}
        done
}

for iface in $mptcpifaces; do
        prepare_rt_table ${iface}
        transfer_routes_ipv4 ${iface}
        replace_rules_ipv4 ${iface}
        transfer_routes_ipv6 ${iface}
        replace_rules_ipv6 ${iface}
done
