#!/bin/bash

set -ex

cd ${0%/*}

RUN_ID="$1"

dnf -y update --best --allowerasing

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
    $NULL

./configure

NCPU=$(getconf _NPROCESSORS_ONLN)

make -j$NCPU all syncheck rpm

cd test

time sudo make \
     KVERSION=$(rpm -qa kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -rn | head -1) \
     TEST_RUN_ID=$RUN_ID \
     -k V=2 \
     SKIP="14 16" \
     check
