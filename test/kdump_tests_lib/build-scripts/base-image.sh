#!/bin/sh

img_inst_pkg grubby\
	dnsmasq\
	openssh openssh-server\
	dracut-network dracut-squash squashfs-tools ethtool snappy

img_run_cmd "grubby --args systemd.journald.forward_to_console=1 systemd.log_target=console --update-kernel ALL"
img_run_cmd "grubby --args selinux=0 --update-kernel ALL"
img_run_cmd "grubby --args crashkernel=224M --update-kernel ALL"
