#!/bin/sh
### hpsa.sh: Called by the parse-hpsa.sh script to create the scan script ###
### Laurence Oberman loberman@redhat.com
. /lib/dracut-lib.sh
### The actual script that scans the hpsa for LUNS
/bin/sh /sbin/hpsa_scan.sh
