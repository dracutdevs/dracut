# stop everything which is not busy
for i in /dev/md* /dev/md/*; do
    [ -b $i ] || continue

    mddetail=$(udevadm info --query=property --name=$i)
    case "$mddetail" in 
	*MD_LEVEL=container*) 
	    ;;
	*DEVTYPE=partition*)
	    ;;
	*)
	    mdadm --stop $i >/dev/null 2>&1
	    ;;
    esac
done
