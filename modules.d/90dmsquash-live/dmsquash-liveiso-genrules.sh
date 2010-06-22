if [ "${root%%:*}" = "liveiso" ]; then
    {
     printf 'KERNEL=="loop0", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/dmsquash-live-root `/sbin/losetup -f --show %s`"\n' \
	  ${root#liveiso:}
    } >> /etc/udev/rules.d/99-liveiso-mount.rules
    echo '[ -e /dev/root ]' > /initqueue-finished/dmsquash.sh
fi
