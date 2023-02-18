#!/bin/bash

set -ex

[[ -d ${0%/*} ]] && cd "${0%/*}"/../

RUN_ID="$1"
TESTS=$2

./configure

NCPU=$(getconf _NPROCESSORS_ONLN)

if ! [[ $TESTS ]]; then
    make -j "$NCPU" all syncheck logtee
else
    make -j "$NCPU" enable_documentation=no all logtee

    cd test

    # shellcheck disable=SC2012
    time LOGTEE_TIMEOUT_MS=590000 make \
        enable_documentation=no \
        KVERSION="$(
            cd /lib/modules
            ls -1 | tail -1
        )" \
        QEMU_CPU="IvyBridge-v2" \
        DRACUT_NO_XATTR=1 \
        TEST_RUN_ID="$RUN_ID" \
        ${TESTS:+TESTS="$TESTS"} \
        -k V=1 \
        check
fi
