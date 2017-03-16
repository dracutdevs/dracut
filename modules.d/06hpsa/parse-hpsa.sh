#!/bin.bash
### Laurence Oberman loberman@redhat.com
### parse-hpsa.sh
### Parses the rd.hpsa=x tp get the host number
### Using rdloaddriver=hpsa will enforce hpsa becoming scsi0

for p in $(getargs rd.hpsa=); do
(
     echo "echo 1 > /sys/class/scsi_host/host$p/rescan" > /sbin/hpsa_scan.sh
    _do_hpsa=1
)
done

### Standard way to call the script from udev
/sbin/initqueue --settled --unique --onetime /bin/sh /sbin/hpsa.sh
#/bin/sh /sbin/hpsa.sh
unset _do_hpsa

