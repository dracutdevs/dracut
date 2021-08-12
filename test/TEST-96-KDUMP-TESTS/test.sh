#!/bin/bash
TEST_DESCRIPTION="kdump tests"

KVERSION=${KVERSION-$(uname -r)}

KEXEC_TOOLS_SRC="kexec-tools"
test_run() {
    KEXEC_TOOLS_TESTDIR="$TESTDIR/"
    # kexec-tools also use TESTDIR variable, don't overwrite it
    testdir_abs=$(realpath "$testdir")
    kdump_tests_lib="$testdir_abs/kdump_tests_lib"
    EXTRA_BUILD_SCRIPT="$testdir_abs/TEST-96-KDUMP_TESTS/build_image.sh" \
      TESTCASEDIR="$testdir_abs/TEST-96-KDUMP_TESTS/testcases" EXTRA_RPMS=$TESTDIR/*.rpm \
      make -C "$KEXEC_TOOLS_TESTDIR" TESTDIR="$KEXEC_TOOLS_TESTDIR"  -f "$kdump_tests_lib/Makefile" test-run V=$V || return 1
    return 0
}


test_setup() {
    make -C "$basedir" DESTDIR="$TESTDIR/" rpm V=$V || return 1
    dnf -y install wget qemu-img || return 1
    return 0
}


test_cleanup() {
    rm -fr -- "$TESTDIR"/*.rpm
    return 0
}

. $testdir/test-functions
