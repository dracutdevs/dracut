#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # do not add this module by default
    return 255
}

depends() {
    return 0
}

install() {
    inst_multiple -o ps grep more cat rm strace free showmount \
        ping netstat rpcinfo vi scp ping6 ssh \
        fsck fsck.ext2 fsck.ext4 fsck.ext3 fsck.ext4dev fsck.vfat e2fsck

}

