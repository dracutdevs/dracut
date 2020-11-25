#!/bin/sh

# ensure wickedd is running
systemctl start wickedd
# detection wrapper around ifup --ifconfig "final xml" all
wicked bootstrap --ifconfig /tmp/dracut.xml all
