#!/bin/sh

# Test RPMs to be installed
TEST_RPMS=
for _rpm in $@; do
	if [[ ! -e $_rpm ]]; then
		perror_exit "'$_rpm' not found"
	else
		TEST_RPMS="$TEST_RPMS $(realpath "$_rpm")"
	fi
done

img_run_cmd "mkdir -p /kexec-kdump-test"
img_inst $BASEDIR/kexec-kdump-test/init.sh /kexec-kdump-test/init.sh
img_inst $BASEDIR/kexec-kdump-test/test.sh /kexec-kdump-test/test.sh
img_inst $BASEDIR/kexec-kdump-test/kexec-kdump-test.service /etc/systemd/system/kexec-kdump-test.service
img_run_cmd "systemctl enable kexec-kdump-test.service"

img_inst_pkg $TEST_RPMS
# Test script should start kdump manually to save time
img_run_cmd "systemctl disable kdump.service"
