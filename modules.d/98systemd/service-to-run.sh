#!/bin/sh

cp -a /lib/systemd/system/dracut*.service /run/systemd/system/
cp -a /lib/systemd/system/initrd-* /run/systemd/system/
cp -a /lib/systemd/system/udevadm*.service /run/systemd/system/

