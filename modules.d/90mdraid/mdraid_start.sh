#!/bin/sh

if $UDEV_QUEUE_EMPTY >/dev/null 2>&1; then
    [ -h "$job" ] && rm -f "$job"
    # run mdadm if udev has settled
    mdadm -IRs
    # and activate any containers
    for md in /dev/md?*; do
        case $md in
            /dev/md*p*) ;;
            *)
                if mdadm --export --detail $md | grep -q container; then
                    mdadm -IR $md
                fi
        esac
    done
fi
