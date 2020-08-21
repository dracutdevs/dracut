#!/bin/sh

systemctl start wickedd
# detection wrapper around ifup --ifconfig "final xml" all
wicked bootstrap --ifconfig /tmp/dracut.xml all
systemctl stop wickedd
