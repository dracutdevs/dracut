#!/bin/sh

dcb=$1

if ! [ -d /sys/firmware/edd ]; then
    modprobe edd
    while ! [ -d /sys/firmware/edd ]; do sleep 0.1; done
fi

for disk in /sys/firmware/edd/int13_*; do
    [ -d $disk ] || continue
    if [ -e ${disk}/pci_dev/driver ]; then
	    driver=`readlink ${disk}/pci_dev/driver`
	    driver=${driver##*/}
    fi
    # i40e uses dev_port 1 for a virtual fcoe function
    if [ "${driver}" == "i40e" ]; then
	    dev_port=1
    fi
    for nic in ${disk}/pci_dev/net/*; do
        [ -d $nic ] || continue
	if [ -n "${dev_port}" -a -e ${nic}/dev_port ]; then
		if [ `cat ${nic}/dev_port` -ne ${dev_port} ]; then
			continue
		fi
	fi
        if [ -e ${nic}/address ]; then
	    fcoe_interface=${nic##*/}
	    if ! [ -e "/tmp/.fcoe-$fcoe_interface" ]; then
		/sbin/fcoe-up $fcoe_interface $dcb
		> "/tmp/.fcoe-$fcoe_interface"
	    fi
        fi
    done
done
modprobe -r edd
