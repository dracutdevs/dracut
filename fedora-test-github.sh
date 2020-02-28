#!/bin/bash

set -ex

[[ -d ${0%/*} ]] && cd ${0%/*}

RUN_ID="$1"
TESTS=$2

# GitHub workflows fetch a clone of the dracut repository which doesn't
# contain git tags, thus "breaking" the RPM build in certain situations
# i.e.:
# DRACUT_MAIN_VERSION in Makefile is defined as an output of `git describe`,
# which in full git clone returns a tag with a numeric version. However,
# without tags it returns SHA of the last commit, which later propagates into
# `Provides:` attribute of the built RPM and can break dependency tree when
# installed
[[ -d .git ]] && git fetch --tags && git describe --tags

./configure

NCPU=$(getconf _NPROCESSORS_ONLN)

if ! [[ $TESTS ]]; then
    make -j$NCPU all syncheck rpm logtee
else
    [[ $TESTS == "99" ]] && make_docs=yes || make_docs=no
    make -j$NCPU enable_documentation=$make_docs all logtee

    cd test

    time LOGTEE_TIMEOUT_MS=590000 make \
         enable_documentation=$make_docs \
         KVERSION=$(rpm -qa kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -rn | head -1) \
         DRACUT_NO_XATTR=1 \
         TEST_RUN_ID=$RUN_ID \
         ${TESTS:+TESTS="$TESTS"} \
         -k V=1 \
         check
fi
