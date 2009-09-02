# stop everything which is not busy
for i in /dev/md*; do
    mdadm --stop $i >/dev/null 2>&1
done
