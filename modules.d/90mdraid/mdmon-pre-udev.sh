# save state dir for mdmon/mdadm for the real root
mkdir /dev/.mdadm
[ -e /var/run/mdadm ] && rm -fr /var/run/mdadm
ln -s /dev/.mdadm /var/run/mdadm
