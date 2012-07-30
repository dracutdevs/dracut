#!/bin/bash

dev=$1
luks=$2

echo "$luks $dev" >> /etc/crypttab
/lib/systemd/system-generators/systemd-cryptsetup-generator
systemctl daemon-reload
systemctl start cryptsetup.target
exit 0
