#!/bin/sh

if $UDEV_QUEUE_EMPTY >/dev/null 2>&1; then
    [ -h "$job" ] && rm -f "$job"
    # run mdadm if udev has settled
    info "Assembling MD RAID arrays"

    # and activate any containers
    for md in /dev/md?*; do
        case $md in
	    /dev/md*p*) ;;
	    *)
		info "Starting MD RAID array $md"
                mdadm -R $md 2>&1 | vinfo
                mdadm -IR $md 2>&1 | vinfo
        esac
    done
fi
