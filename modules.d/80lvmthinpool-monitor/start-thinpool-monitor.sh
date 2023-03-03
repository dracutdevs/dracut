#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

LVS=$(getargs rd.lvm.lv -d rd_LVM_LV=)

is_lvm2_thinp_device() {
    _device_path=$1
    _lvm2_thin_device=$(lvm lvs -S 'lv_layout=sparse && lv_layout=thin' \
        --nosuffix --noheadings -o vg_name,lv_name "$_device_path" 2> /dev/null)

    [ -n "$_lvm2_thin_device" ] && return $?
}

for LV in $LVS; do
    if is_lvm2_thinp_device "/dev/$LV"; then
        THIN_POOLS="$(lvm lvs -S 'lv_layout=sparse && lv_layout=thin' \
            --nosuffix --noheadings -o vg_name,pool_lv "$LV" \
            | awk '{printf("%s/%s",$1,$2);}') $THIN_POOLS"
    fi
done

THIN_POOLS=$(echo "$THIN_POOLS" | tr ' ' '\n' | sort -u | tr '\n' ' ')

if [ -n "$THIN_POOLS" ]; then
    if [ -e "/etc/lvm/lvm.conf" ]; then
        # Use 'monitoring=0' to override the value in lvm.conf, in case
        # dmeventd monitoring been started after the calling.
        CONFIG="activation {monitoring=0}"
    else
        CONFIG="activation {monitoring=0 thin_pool_autoextend_threshold=70 thin_pool_autoextend_percent=20}"
    fi

    # Activate the thinpool in case the thinpool is in inactive state.
    # Otherwise lvextend will fail.
    for THIN_POOL in $THIN_POOLS; do
        lvm lvchange -ay "$THIN_POOL" --config "$CONFIG"
    done

    while true; do
        for THIN_POOL in $THIN_POOLS; do
            lvm lvextend --use-policies --config "$CONFIG" "$THIN_POOL"
        done
        sleep 5
    done &
    echo $! > /run/thinpool-moni.pid
fi
