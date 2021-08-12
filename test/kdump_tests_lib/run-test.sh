#!/bin/bash

_kill_all_jobs() {
	local _jobs=$(jobs -r -p)

	[ -n "$_jobs" ] && kill $_jobs
}

trap '
ret=$?;
_kill_all_jobs
exit $ret;
' EXIT

trap 'exit 1;' SIGINT

BASEDIR=$(realpath $(dirname "$0"))
. $BASEDIR/test-lib.sh

if [ -z "$TESTCASEDIR" ]; then
    TESTCASEDIR="$TESTDIR/testcases"
fi
[[ ! -d "$TESTCASEDIR" ]] && echo "testcases not found in $TESTCASEDIR" && exit 1

console=0
testcases=""

while [ $# -gt 0 ]; do
	case $1 in
		'')
			break
			;;
		--console )
			console=1
			;;
		-*)
			echo "Invalid option $1"
			;;
		*)
			testcases+=" $1"
			;;
	esac
	shift;
done

if [ -z "$testcases" ]; then
	echo "==== Starting all tests: ===="
	testcases=$(ls -1 $TESTCASEDIR)
else
	echo "==== Starting specified tests: ===="
fi
echo ${testcases##*/}
echo

declare -A results
ret=0

for test_case in $testcases; do
	echo "======== Running Test Case $test_case ========"
	results[$test_case]="<Test Skipped>"

	testdir=$TESTCASEDIR/$test_case
	script_num=$(ls -1 $testdir | wc -l)
	scripts=$(ls -r -1 $testdir | tr '\n' ' ')
	test_outputs=""
	read main_script aux_script <<< "$scripts"

	if [ -z "$main_script" ]; then
		echo "ERROR: Empty testcase dir $testdir"
		continue
	fi

	for script in $scripts; do
		echo "---- Building image for: $script ----"
		echo "-------- Output image is: $(get_test_image $testdir/$script)"
		echo "-------- Building log is: $(get_test_image $testdir/$script).log"

		mkdir -p $(dirname $(get_test_image $testdir/$script))
		build_test_image $testdir/$script &> $(get_test_image $testdir/$script).log

		if [ $? -ne 0 ]; then
			echo "Failing building image!"
			continue 2
		fi
	done

	for script in $aux_script; do
		echo "---- Starting VM: $script ----"

		script="$testdir/$script"
		echo "-------- Qemu cmdline: $(get_test_qemu_cmd_file $script)"
		echo "-------- Console log: $(get_test_console_file $script)"
		echo "-------- Test log: $(get_test_output_file $script)"
		test_outputs+="$(get_test_output_file $script) "

		rm -f $(get_test_console_file $script)
		rm -f $(get_test_output_file $script)

		$(run_test_sync $script > $(get_test_console_file $script)) &

		sleep 5
	done

	script="$main_script"
	echo "---- Starting test VM: $(basename $script) ----"
	script="$testdir/$script"

	echo "-------- Qemu cmdline: $(get_test_qemu_cmd_file $script)"
	echo "-------- Console log: $(get_test_console_file $script)"
	echo "-------- Test log: $(get_test_output_file $script)"
	test_outputs+="$(get_test_output_file $script) "

	rm -f $(get_test_console_file $script)
	rm -f $(get_test_output_file $script)

	if [ $console -eq 1 ]; then
		run_test_sync $script | tee $(get_test_console_file $script)
		[ -n "$(jobs -p)" ] && kill $(jobs -p)
	else
		$(run_test_sync $script > $(get_test_console_file $script)) &
		watch_test_outputs $test_outputs
	fi

	res="$(gather_test_result $test_outputs)"

	[ $? -ne 0 ] && ret=$(expr $ret + 1)
	results[$test_case]="$res"

	echo -e "-------- Test finished: $test_case $res --------"
	for script in $scripts; do
		script="$testdir/$script"
		output="$(get_test_output_file $script) "
		image="$(get_test_image $script)"
		vmcore="$(sed -n 's/^VMCORE: \(\S*\).*/\1/p' $output)"
		kernel="$(sed -n 's/^KERNEL VERSION: \(\S*\).*/\1/p' $output)"
		if [ -n "$vmcore" ]; then
			echo "You can retrive the verify the vmcore file using following command:"
			echo "./copy-from-image.sh \\"
			echo "    $image \\"
			echo "    $vmcore ./"
			echo "Kernel package verion is: $kernel"
		fi
	done
done

echo "======== Test results ========"
for i in ${!results[@]}; do
	echo "----------------"
	echo -e "$i:\t\t${results[$i]}"
done

exit $ret
