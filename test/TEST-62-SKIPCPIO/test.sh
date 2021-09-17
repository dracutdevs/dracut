#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# shellcheck disable=SC2034
TEST_DESCRIPTION="test skipcpio"

test_check() {
    which cpio dd truncate find sort diff &> /dev/null
}

skipcpio_simple() {
    mkdir -p "$CPIO_TESTDIR/skipcpio_simple/first_archive"
    pushd "$CPIO_TESTDIR/skipcpio_simple/first_archive"

    for ((i = 0; i < 3; i++)); do
        echo "first archive file $i" >> ./"$i"
    done
    find . -print0 | sort -z \
        | cpio -o --null -H newc --file "$CPIO_TESTDIR/skipcpio_simple.cpio"
    popd

    mkdir -p "$CPIO_TESTDIR/skipcpio_simple/second_archive"
    pushd "$CPIO_TESTDIR/skipcpio_simple/second_archive"

    for ((i = 10; i < 13; i++)); do
        echo "second archive file $i" >> ./"$i"
    done

    find . -print0 | sort -z \
        | cpio -o --null -H newc >> "$CPIO_TESTDIR/skipcpio_simple.cpio"
    popd

    cpio -i --list < "$CPIO_TESTDIR/skipcpio_simple.cpio" \
        > "$CPIO_TESTDIR/skipcpio_simple.list"
    cat << EOF | diff - "$CPIO_TESTDIR/skipcpio_simple.list"
.
0
1
2
EOF

    "$basedir"/src/skipcpio/skipcpio "$CPIO_TESTDIR/skipcpio_simple.cpio" \
        | cpio -i --list > "$CPIO_TESTDIR/skipcpio_simple.list"
    cat << EOF | diff - "$CPIO_TESTDIR/skipcpio_simple.list"
.
10
11
12
EOF
}

test_run() {
    set -x
    set -e

    skipcpio_simple

    return 0
}

test_setup() {
    CPIO_TESTDIR=$(mktemp --directory -p "$TESTDIR" cpio-test.XXXXXXXXXX) \
        || return 1
    export CPIO_TESTDIR
    return 0
}

test_cleanup() {
    [ -d "$CPIO_TESTDIR" ] && rm -rf "$CPIO_TESTDIR"
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
