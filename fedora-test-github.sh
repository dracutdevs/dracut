#!/bin/bash

set -ex

[[ -d ${0%/*} ]] && cd ${0%/*}

RUN_ID="$1"
TESTS=$2

./configure

NCPU=$(getconf _NPROCESSORS_ONLN)

if ! [[ $TESTS ]]; then
    make -j$NCPU all syncheck rpm logtee
else
    make -j$NCPU all logtee

    cd test

    time LOGTEE_TIMEOUT_MS=590000 make \
         KVERSION=$(rpm -qa kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -rn | head -1) \
         DRACUT_NO_XATTR=1 \
         TEST_RUN_ID=$RUN_ID \
         ${TESTS:+TESTS="$TESTS"} \
         -k V=1 \
         check
fi
