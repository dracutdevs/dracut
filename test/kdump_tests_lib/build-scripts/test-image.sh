#!/usr/bin/env bash
. $BASEDIR/test-lib.sh
TEST_SCRIPT=$1

QEMU_CMD="$DEFAULT_QEMU_CMD \
-serial stdio \
-serial file:$(get_test_output_file $TEST_SCRIPT) \
-monitor none \
-hda $OUTPUT_IMAGE"

img_add_qemu_cmd() {
	QEMU_CMD+=" $@"
}

source $TEST_SCRIPT

on_build

img_inst $TEST_SCRIPT /kexec-kdump-test/test.sh

echo $QEMU_CMD > $(get_test_qemu_cmd_file $TEST_SCRIPT)
