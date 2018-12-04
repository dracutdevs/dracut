#!/bin/bash

set -ex

[[ -d ${0%/*} ]] && cd ${0%/*}

RUN_ID="$1"
TESTS=$2

dnf -y update --best --allowerasing &>/dev/null

dnf -y install --best --allowerasing \
    dash \
    asciidoc \
    mdadm \
    lvm2 \
    dmraid \
    cryptsetup \
    nfs-utils \
    nbd \
    dhcp-server \
    scsi-target-utils \
    iscsi-initiator-utils \
    strace \
    btrfs-progs \
    kmod-devel \
    gcc \
    bzip2 \
    xz \
    tar \
    wget \
    rpm-build \
    make \
    git \
    bash-completion \
    sudo \
    kernel \
    dhcp-client \
    /usr/bin/qemu-kvm \
    /usr/bin/qemu-system-$(uname -i) \
    e2fsprogs \
    tcpdump \
    $NULL &>/dev/null

./configure

NCPU=$(getconf _NPROCESSORS_ONLN)

if ! [[ $TESTS ]]; then
    make -j$NCPU all syncheck rpm logtee
else
    make -j$NCPU all logtee

    cd test

    time sudo make \
         KVERSION=$(rpm -qa kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -rn | head -1) \
         TEST_RUN_ID=$RUN_ID \
         ${TESTS:+TESTS="$TESTS"} \
         -k V=2 \
         check
fi
