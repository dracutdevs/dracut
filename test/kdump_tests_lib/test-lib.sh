#!/usr/bin/env sh
[ -z "$BASEDIR" ] && BASEDIR=$(realpath $(dirname "$0"))
[ -z "$TESTDIR" ] && TESTDIR=$(realpath ./)
[ -z "$TEST_BASE_IMAGE" ] && TEST_BASE_IMAGE=$TESTDIR/output/test-base-image

[[ ! -e $TEST_BASE_IMAGE ]] && echo "Test base image not found." && exit 1

DEFAULT_QEMU_CMD="-nodefaults \
-nographic \
-smp 2 \
-m 768M \
-monitor none"

_YELLOW='\033[1;33m'
_GREEN='\033[0;32m'
_RED='\033[0;31m'
_NC='\033[0m' # No Color

get_test_path() {
	local script=$1
	local testname=$(basename $(dirname $script))
	local output=$TESTDIR/output/$testname

	echo $output
}

get_test_entry_name() {
	echo $(basename ${1%.*})
}

get_test_image() {
	local script=$1
	local testout=$(get_test_path $script)
	local entry=$(get_test_entry_name $script)

	echo $testout/$entry.img
}

get_test_qemu_cmd_file() {
	local script=$1
	local testout=$(get_test_path $script)
	local entry=$(get_test_entry_name $script)

	echo $testout/$entry.qemu_cmd
}

get_test_qemu_cmd() {
	cat $(get_test_qemu_cmd_file $1)
}

get_test_output_file() {
	local script=$1
	local testout=$(get_test_path $script)
	local entry=$(get_test_entry_name $script)

	echo $testout/$entry.output
}

get_test_console_file() {
	local script=$1
	local testout=$(get_test_path $script)
	local entry=$(get_test_entry_name $script)

	echo $testout/$entry.console
}

get_test_output() {
	local output=$(get_test_output_file $1)
	if [ -e "$output" ]; then
		cat $(get_test_output_file $1)
	else
		echo "<No Output>"
	fi
}

build_test_image() {
	local script=$1
	local test_image=$(get_test_image $script)
	mkdir -p $(dirname $test_image)

	$BASEDIR/build-image.sh \
		$TEST_BASE_IMAGE \
		$test_image \
		$BASEDIR/build-scripts/test-image.sh \
		$script
}

run_test_sync() {
	local qemu_cmd=$(get_test_qemu_cmd $1)

	if [ -n "$qemu_cmd" ]; then
		timeout --foreground 10m $BASEDIR/run-qemu $(get_test_qemu_cmd $1)
	else
		echo "error: test qemu command line is not configured" > /dev/stderr
		return 1
	fi
}

_check_test_result() {
	grep "TEST PASSED" $1 2>/dev/null
	[ $? -eq 0 ] && return 0

	grep "TEST FAILED" $1 2>/dev/null
	[ $? -eq 0 ] && return 1

	grep "TEST ABORTED" $1 2>/dev/null
	[ $? -eq 0 ] && return 2

	return 255
}

# Print test result and return below value:
# 0: Test passed
# 1: Test failed
# 2: Test aborted, test scripts errored out
# 3: Test exited unexpectely, VM got killed early, or time out
gather_test_result() {
	local ret=255
	local res=""

	for i in $@; do
		res=$(_check_test_result $i)
		ret=$?

		if [ $ret -ne 255 ]; then
			echo $res
			return $ret
		fi
	done

	echo "${_RED}TEST RESULT NOT FOUND!${_NC}"
	return 3
}

# Wait and watch for test result
watch_test_outputs() {
	local ret=255
	local res=""
	# If VMs are still running, check for test result, if
	# test finished, kill remaining VMs
	while true; do
		if [ -n "$(jobs -r)" ]; then
			# VMs still running
			for i in $@; do
				res=$(_check_test_result $i)
				ret=$?

				if [ $ret -ne 255 ]; then
					# Test finished, kill VMs
					kill $(jobs -p)
					break 2
				fi
			done
		else
			# VMs exited
			ret=255

			for i in $@; do
				res=$(_check_test_result $i)
				ret=$?

				if [ $ret -ne 255 ]; then
					break 2
				fi
			done

			if [ $ret -eq 255 ]; then
				ret=3
				break
			fi
		fi

		sleep 1
	done

	return $ret
}
