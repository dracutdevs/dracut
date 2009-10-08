#!/bin/sh

# config file syntax:
# deviceno   WWPN   FCPLUN
#
# Example:
# 0.0.4000 0x5005076300C213e9 0x5022000000000000 
# 0.0.4001 0x5005076300c213e9 0x5023000000000000 
#
#
# manual setup:
# modprobe zfcp
# echo 1    > /sys/bus/ccw/drivers/zfcp/0.0.4000/online
# echo LUN  > /sys/bus/ccw/drivers/zfcp/0.0.4000/WWPN/unit_add
# 
# Example:
# modprobe zfcp
# echo 1                  > /sys/bus/ccw/drivers/zfcp/0.0.4000/online
# echo 0x5022000000000000 > /sys/bus/ccw/drivers/zfcp/0.0.4000/0x5005076300c213e9/unit_add

CONFIG=/etc/zfcp.conf
PATH=/bin:/usr/bin:/sbin:/usr/sbin

if [ -f "$CONFIG" ]; then
   if [ ! -d /sys/bus/ccw/drivers/zfcp ]; then
      modprobe zfcp
   fi
   if [ ! -d /sys/bus/ccw/drivers/zfcp ]; then
      return
   fi
   tr "A-Z" "a-z" < $CONFIG| while read line; do
       case $line in
	   \#*) ;;
	   *)
	       [ -z "$line" ] && continue
	       set $line
	       if [ $# -eq 5 ]; then
		   DEVICE=$1
		   SCSIID=$2
		   WWPN=$3
		   SCSILUN=$4
		   FCPLUN=$5
		   echo "Warning: Deprecated values in /etc/zfcp.conf, ignoring SCSI ID $SCSIID and SCSI LUN $SCSILUN"
	       elif [ $# -eq 3 ]; then
		   DEVICE=${1##*0x}
		   WWPN=$2
		   FCPLUN=$3
	       fi
	       echo 1 > /sys/bus/ccw/drivers/zfcp/${DEVICE}/online
	       [ ! -d /sys/bus/ccw/drivers/zfcp/${DEVICE}/${WWPN}/${FCPLUN} ] \
		   && echo $FCPLUN > /sys/bus/ccw/drivers/zfcp/${DEVICE}/${WWPN}/unit_add
	       ;;
       esac
   done
fi
