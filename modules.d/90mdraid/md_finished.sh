for f in /initqueue-settled/mdcontainer_start* /initqueue-settled/mdraid_start* /initqueue-settled/mdadm_auto*; do
    [ -e $f ] && return 1
done

$UDEV_QUEUE_EMPTY >/dev/null 2>&1 || return 1

return 0
