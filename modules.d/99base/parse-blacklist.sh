#!/bin/sh

for p in $(getargs rdblacklist=); do 
     echo "blacklist $p" >> /etc/modprobe.d/initramfsblacklist.conf
done
