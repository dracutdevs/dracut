#!/usr/bin/env sh
BOOT_ARG="test_boot_count"
_YELLOW='\033[1;33m'
_GREEN='\033[0;32m'
_RED='\033[0;31m'
_NC='\033[0m' # No Color

if [ -n "$(cat /proc/cmdline | grep "\bno_test\b")" ]; then
	exit 0
fi

get_test_boot_count() {
	local boot_count=$(cat /proc/cmdline | sed -n "s/.*$BOOT_ARG=\([0-9]*\).*/\1/p")

	if [ -z "$boot_count" ]; then
		boot_count=1
	fi

	echo $boot_count
}

test_output() {
	echo $@ > /dev/ttyS1
	echo $@ > /dev/ttyS0

	sync
}

test_passed() {
	echo -e "${_GREEN}TEST PASSED${_NC}" > /dev/ttyS1
	echo -e "${_GREEN}kexec-kdump-test: TEST PASSED${_NC}" > /dev/ttyS0

	echo $@ > /dev/ttyS1
	echo $@ > /dev/ttyS0

	sync

	shutdown -h 0

	exit 0
}

test_failed() {
	echo -e "${_RED}TEST FAILED${_NC}" > /dev/ttyS1
	echo -e "${_RED}kexec-kdump-test: TEST FAILED${_NC}" > /dev/ttyS0

	echo $@ > /dev/ttyS1
	echo $@ > /dev/ttyS0

	sync

	shutdown -h 0

	exit 1
}

test_abort() {
	echo -e "${_YELLOW}TEST ABORTED${_NC}" > /dev/ttyS1
	echo -e "${_YELLOW}kexec-kdump-test: TEST ABORTED${_NC}" > /dev/ttyS0

	echo $@ > /dev/ttyS1
	echo $@ > /dev/ttyS0

	sync

	shutdown -h 0

	exit 2
}

has_valid_vmcore_dir() {
	local path=$1
	local vmcore_dir=$path/$(ls -1 $path | tail -n 1)
	local vmcore="<invalid>"

	test_output "Found a vmcore dir \"$vmcore_dir\":"
	# Checking with `crash` is slow and consume a lot of memory/disk,
	# just do a sanity check by check if log are available.
	if [ -e $vmcore_dir/vmcore ]; then
		vmcore=$vmcore_dir/vmcore
		makedumpfile --dump-dmesg $vmcore $vmcore_dir/vmcore-dmesg.txt.2 || {
			test_output "Failed to retrive dmesg from vmcore!"
			return 1
		}
	elif [ -e $vmcore_dir/vmcore.flat ]; then
		vmcore=$vmcore_dir/vmcore.flat
		makedumpfile -R $vmcore_dir/vmcore < $vmcore || return 1
		makedumpfile --dump-dmesg $vmcore_dir/vmcore $vmcore_dir/vmcore-dmesg.txt.2 || {
			test_output "Failed to retrive dmesg from vmcore!"
			return 1
		}
		rm $vmcore_dir/vmcore
	else
		test_output "The vmcore dir is empty!"
		return 1
	fi

	if ! diff -w $vmcore_dir/vmcore-dmesg.txt.2 $vmcore_dir/vmcore-dmesg.txt; then
		test_output "Dmesg retrived from vmcore is different from dump version!"
		return 1
	fi

	test_output "VMCORE: $vmcore"
	test_output "KERNEL VERSION: $(rpm -q kernel-core)"

	return 0
}

BOOT_COUNT=$(get_test_boot_count)
test_output "Kexec-Kdump-Test Boot #$BOOT_COUNT"

echo 'fedora' | passwd --stdin root

test_output "Updating kernel cmdline"
grubby --update-kernel ALL --args $BOOT_ARG=$(expr $BOOT_COUNT + 1) && sync

test_output "Executing test hook"
source /kexec-kdump-test/test.sh

on_test;

test_output "Test exited, system hang for inspect"
