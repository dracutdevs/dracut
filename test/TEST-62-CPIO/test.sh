#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

TEST_DESCRIPTION="test skipcpio and padcpio utilities"

test_check() {
    which cpio dd truncate find sort diff &>/dev/null
}

skipcpio_simple() {
    mkdir -p "$CPIO_TESTDIR/skipcpio_simple/first_archive"
    pushd "$CPIO_TESTDIR/skipcpio_simple/first_archive"

    for ((i=0; i < 3; i++)); do
        echo "first archive file $i" >> ./$i
    done
    find . -print0 | sort -z \
        | cpio -o --null -H newc --file "$CPIO_TESTDIR/skipcpio_simple.cpio"
    popd

    mkdir -p "$CPIO_TESTDIR/skipcpio_simple/second_archive"
    pushd "$CPIO_TESTDIR/skipcpio_simple/second_archive"

    for ((i=10; i < 13; i++)); do
        echo "second archive file $i" >> ./$i
    done
    # could also use the new cpio --chain option here...
    find . -print0 | sort -z \
        | cpio -o --null -H newc >> "$CPIO_TESTDIR/skipcpio_simple.cpio"
    popd

    cat "$CPIO_TESTDIR/skipcpio_simple.cpio" | cpio -i --list \
        > "$CPIO_TESTDIR/skipcpio_simple.list"
    cat <<EOF | diff - "$CPIO_TESTDIR/skipcpio_simple.list"
.
0
1
2
EOF

    $basedir/skipcpio/skipcpio "$CPIO_TESTDIR/skipcpio_simple.cpio" \
        | cpio -i --list > "$CPIO_TESTDIR/skipcpio_simple.list"
    cat <<EOF | diff - "$CPIO_TESTDIR/skipcpio_simple.list"
.
10
11
12
EOF
}

# simple test with three filled files, all data segments should be aligned
padcpio_simple() {
    local f1_content="This data will be aligned at 4K"
    local f2_content="This data will be aligned at 8K"
    local f3_content="This data will be aligned at 16K"

    mkdir -p "$CPIO_TESTDIR/padcpio_simple"
    echo "$f1_content" > "$CPIO_TESTDIR/padcpio_simple/f1"
    echo "$f2_content" > "$CPIO_TESTDIR/padcpio_simple/f2"
    truncate --size 6K "$CPIO_TESTDIR/padcpio_simple/f2"
    echo "$f3_content" > "$CPIO_TESTDIR/padcpio_simple/f3"

    pushd "$CPIO_TESTDIR/padcpio_simple"
    echo -n -e "f1\0f2\0f3\0" \
        | $basedir/skipcpio/padcpio --align 4096 --paddir pad \
        | cpio -o --null -H newc --file "$CPIO_TESTDIR/padcpio_simple.cpio"
    popd

    dd status=none bs=1 skip=4096 count="${#f1_content}" \
       if="$CPIO_TESTDIR/padcpio_simple.cpio" | grep "$f1_content"
    dd status=none bs=1 skip=8192 count="${#f2_content}" \
       if="$CPIO_TESTDIR/padcpio_simple.cpio" | grep "$f2_content"
    dd status=none bs=1 skip=16384 count="${#f3_content}" \
       if="$CPIO_TESTDIR/padcpio_simple.cpio"  | grep "$f3_content"
    cpio -i --list --file "$CPIO_TESTDIR/padcpio_simple.cpio" \
        > "$CPIO_TESTDIR/padcpio_simple.list"
    cat <<EOF | diff - "$CPIO_TESTDIR/padcpio_simple.list"
pad
pad/0
f1
pad/1
f2
pad/2
f3
EOF
}

# three files only one above --min threshold, 4k alignment
padcpio_min() {
    local f1_content="THIS data will be unaligned"
    local f2_content="this data will be unaligned"
    local f3_content="This data will be aligned at 4K"

    mkdir -p "$CPIO_TESTDIR/padcpio_min"
    echo "$f1_content" > "$CPIO_TESTDIR/padcpio_min/f1"
    echo "$f2_content" > "$CPIO_TESTDIR/padcpio_min/f2"
    echo "$f3_content" > "$CPIO_TESTDIR/padcpio_min/f3"
    truncate --size 4K "$CPIO_TESTDIR/padcpio_min/f3"

    pushd "$CPIO_TESTDIR/padcpio_min"
    find . -print0 | sort -z \
        | $basedir/skipcpio/padcpio --min 4K --align 4K --paddir pad \
        | cpio -o --null -H newc --file "$CPIO_TESTDIR/padcpio_min.cpio"
    popd

    dd status=none bs=1 skip=4096 count="${#f3_content}" \
       if="$CPIO_TESTDIR/padcpio_min.cpio" | grep "$f3_content"
}

# GNU cpio defers hardlink processing until the last link is encountered. To
# avoid this tracking padcpio just puts them (unaligned) at the end of the
# archive.
padcpio_links() {
    mkdir -p "$CPIO_TESTDIR/padcpio_links"
    echo "this is hardlinked" > "$CPIO_TESTDIR/padcpio_links/f1"
    ln "$CPIO_TESTDIR/padcpio_links/f1" "$CPIO_TESTDIR/padcpio_links/f2"
    echo "this is a symlink target" > "$CPIO_TESTDIR/padcpio_links/f3"
    truncate --size 6K "$CPIO_TESTDIR/padcpio_links/f3"
    ln -s "f3" "$CPIO_TESTDIR/padcpio_links/f4"

    pushd "$CPIO_TESTDIR/padcpio_links"
    echo -n -e "f1\0f2\0f3\0f4\0" \
        | $basedir/skipcpio/padcpio --align 4096 --paddir paddy \
        | cpio -o --null -H newc --file "$CPIO_TESTDIR/padcpio_links.cpio"
    popd

    cpio -i --list --file "$CPIO_TESTDIR/padcpio_links.cpio" \
        > "$CPIO_TESTDIR/padcpio_links.list"
    cat <<EOF | diff - "$CPIO_TESTDIR/padcpio_links.list"
paddy
paddy/0
f3
f4
f1
f2
EOF
}

test_run() {
    set -x
    set -e

    skipcpio_simple

    padcpio_simple
    padcpio_min
    padcpio_links

    return 0
}

test_setup() {
    export CPIO_TESTDIR=$(mktemp --directory -p "$TESTDIR" cpio-test.XXXXXXXXXX)
    return 0
}

test_cleanup() {
    [ -d "$CPIO_TESTDIR" ] && rm -rf "$CPIO_TESTDIR"
    return 0
}

. $testdir/test-functions
