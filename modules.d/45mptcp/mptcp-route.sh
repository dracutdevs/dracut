#!/bin/sh

type getargbool >/dev/null 2>&1 || . /lib/dracut-lib.sh
. /lib/net-lib.sh

if getargbool 0 rd.live.debug -n -y rdlivedebug; then
    exec > /tmp/liveroot.$$.out
    exec 2>> /tmp/liveroot.$$.out
    set -x
fi

if [ -e /tmp/mptcp.info ]; then
    . /tmp/mptcp.info
elif [ -e /tmp/mptcp.info.up ]; then
    return
else
    return
fi

set -e

prepare_rt_table() {
    local rttables=/etc/iproute2/rt_tables
    local iface=$1
    if ! egrep -q "\s${iface}\s*"\$ $rttables; then
        idx=$(wc -l <$rttables)
        echo -e "$(( 100 + ${idx} ))\t${iface}" >> $rttables
    fi
}

get_ipv4_addressses() {
    local iface=$1
    ip -4 addr show dev ${iface} | sed -rn '/inet / s_^.*inet ([0-9.]*)/.*$_\1_p'
}

get_ipv6_addressses() {
    local iface=$1
    ip -6 addr show dev ${iface} | sed -rn '/inet6 / s_^.*inet6 ([0-9a-f:]*)/.*$_\1_p'
}

transfer_routes_ipv4() {
    local iface=$1
    local tableid=$(get_table_id $iface)
    ip -4 route flush table ${tableid}
    cat /etc/iproute2/rt_tables | vwarn
    $(ip -4 rou show table main | grep "dev ${iface}" | sed -r 's_expires [^ ]*__' | sed -r 's_proto [^ ]*__' ) | while read line; do
        [[ -z "$line" ]] && continue
        ip -4 route add ${line} table ${tableid} dev ${iface}
    done
}

transfer_routes_ipv6() {
    local iface=$1
    local tableid=$(get_table_id $iface)
    ip -6 route flush table ${tableid}
    $(ip -6 route show table main | grep "dev ${iface}" | sed -r 's_expires [^ ]*__' | sed -r 's_proto [^ ]*__' ) | while read line; do
        [[ -z "$line" ]] && continue
        ip -6 route add ${line} table ${tableid} dev ${iface}
    done
}

get_table_id() {
    local rttables=/etc/iproute2/rt_tables
    local table=$1
    sed -rn "/^\s*[0-9]*\s*${table}/ s_^\s*([0-9]+)\s.*_\1_p" $rttables
}

replace_rules_ipv4() {
    local iface=$1
    local tableid=$(get_table_id $iface)
    while ip -4 rule show | egrep -q ^${tableid}; do
        ip -4 rule del prio ${tableid}
    done
    for ipaddr in $(get_ipv4_addressses ${iface}); do
        ip -4 rule add prio ${tableid} from ${ipaddr} table ${tableid} dev ${iface}
    done
}

replace_rules_ipv6() {
    local iface=$1
    local tableid=$(get_table_id $iface)
    while ip -6 rule show | egrep -q ^${tableid}; do
        ip -6 rule del prio ${tableid}
    done
    for ipaddr in $(get_ipv6_addressses ${iface}); do
        echo $ipaddr | egrep -q '^fe80:' && continue
        ip -6 rule add prio ${tableid} from ${ipaddr} table ${tableid} dev ${iface}
    done
}

for iface in $mptcpifaces; do
    [ -e /tmp/net.$iface.up ] || linkup ${iface}
    prepare_rt_table ${iface}
    transfer_routes_ipv4 ${iface}
    replace_rules_ipv4 ${iface}
    transfer_routes_ipv6 ${iface}
    replace_rules_ipv6 ${iface}
done

touch /tmp/mptcp.info.up
