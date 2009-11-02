#!/bin/sh

# config file syntax:
# deviceno   sysfs_opts...
#
# Examples:
# 0.0.0203 readonly=1 failfast=1
# 0.0.0204
# 0.0.0205 erplog=1

CONFIG=/etc/dasd.conf
PATH=/bin:/usr/bin:/sbin:/usr/sbin

if [ -f "$CONFIG" ]; then
    if [ ! -d /sys/bus/ccw/drivers/dasd-eckd ] && [ ! -d /sys/bus/ccw/drivers/dasd-fba ]; then
        return
    fi
    tr "A-Z" "a-z" < $CONFIG | while read line; do
        case $line in
            \#*) ;;
            *)
                [ -z "$line" ] && continue
                set $line
                DEVICE=$1
                SYSFSPATH=
                if [ -r "/sys/bus/ccw/drivers/dasd-eckd/$DEVICE" ]; then
                    SYSFSPATH="/sys/bus/ccw/drivers/dasd-eckd/$DEVICE"
                elif [ -r "/sys/bus/ccw/drivers/dasd-fba/$DEVICE" ]; then
                    SYSFSPATH="/sys/bus/ccw/drivers/dasd-fba/$DEVICE"
                else
                    continue
                fi
                echo 1 > $SYSFSPATH/online
                shift
                while [ ! -z "$1" ]; do
                    (
                        attribute="$1"
                        IFS="="
                        set $attribute
                        case "$1" in
                            readonly|use_diag|erplog|failfast)
                                if [ -r "$SYSFSPATH/$1" ]; then
                                    echo $2 > $SYSFSPATH/$1
                                fi
                                ;;
                        esac
                    )
                    shift
                done
                echo
                ;;
        esac
    done
fi
