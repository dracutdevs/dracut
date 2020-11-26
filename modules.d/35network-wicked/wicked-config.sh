#!/bin/sh

getcmdline > /tmp/cmdline.$$.conf
wicked show-config --ifconfig dracut:cmdline:/tmp/cmdline.$$.conf > /tmp/dracut.xml
rm -f /tmp/cmdline.$$.conf
