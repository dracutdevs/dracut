#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# shellcheck disable=SC2034
TEST_DESCRIPTION="kernel cpio extraction tests for dracut-cpio"
# see dracut-cpio source for unit tests

test_check() {
    if ! [[ -x "$PKGLIBDIR/dracut-cpio" ]]; then
        echo "Test needs dracut-cpio... Skipping"
        return 1
    fi
}

test_dracut_cpio() {
    local tdir="${CPIO_TESTDIR}/${1}"
    shift
    # --enhanced-cpio tells dracut to use dracut-cpio instead of GNU cpio
    local dracut_cpio_params=("--enhanced-cpio" "$@")

    mkdir -p "$tdir"

    # VM script to print sentinel on boot
    # write to kmsg so that sysrq messages don't race with console output
    cat > "$tdir/init.sh" << EOF
echo "Image with ${dracut_cpio_params[*]} booted successfully" > /dev/kmsg
echo 1 > /proc/sys/kernel/sysrq
echo o > /proc/sysrq-trigger
sleep 20
EOF

    "$DRACUT" -l --drivers "" \
        "${dracut_cpio_params[@]}" \
        --modules "bash base" \
        --include "$tdir/init.sh" /var/lib/dracut/hooks/emergency/00-init.sh \
        --no-hostonly --no-hostonly-cmdline \
        "$tdir/initramfs" \
        || return 1

    "$testdir"/run-qemu \
        -device i6300esb -watchdog-action poweroff \
        -daemonize -pidfile "$tdir/vm.pid" \
        -serial "file:$tdir/console.out" \
        -append "panic=1 oops=panic softlockup_panic=1 loglevel=7 console=ttyS0 rd.shell=1" \
        -initrd "$tdir/initramfs" || return 1

    timeout=120
    while [[ -f $tdir/vm.pid ]] \
        && ps -p "$(head -n1 "$tdir/vm.pid")" > /dev/null; do
        echo "$timeout - awaiting VM shutdown"
        sleep 1
        [[ $((timeout--)) -le 0 ]] && return 1
    done

    cat "$tdir/console.out"
    grep -q "Image with ${dracut_cpio_params[*]} booted successfully" \
        "$tdir/console.out"
}

test_run() {
    set -x

    # dracut-cpio is typically used with compression and strip disabled, to
    # increase the chance of (reflink) extent sharing.
    test_dracut_cpio "simple" "--no-compress" "--nostrip" || return 1
    # dracut-cpio should still work fine with compression and stripping enabled
    test_dracut_cpio "compress" "--gzip" "--nostrip" || return 1
    test_dracut_cpio "strip" "--gzip" "--strip" || return 1
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
