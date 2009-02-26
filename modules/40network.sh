#!/bin/bash
dracut_install ip dhclient
inst "$dsrc/ifup" "/sbin/ifup"
inst "$dsrc/dhclient-script" "/sbin/dhclient-script"
instmods =networking ecb arc4
inst_rules "$dsrc/rules.d/60-net.rules"
inst_hook pre-pivot 10 "$dsrc/hooks/kill-dhclient.sh"
inst_hook pre-mount 70 "$dsrc/hooks/run-dhclient.sh"
