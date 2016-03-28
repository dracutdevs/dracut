#!/bin/bash

# called by dracut
check() {
    # do not add this module by default
    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_multiple -o cat ls ps grep more cat rm strace free showmount \
                  ping netstat rpcinfo vi scp ping6 ssh find vi \
                  tcpdump cp less hostname mkdir \
                  fsck fsck.ext2 fsck.ext4 fsck.ext3 fsck.ext4dev fsck.vfat e2fsck

    grep '^tcpdump:' /etc/passwd 2>/dev/null >> "$initdir/etc/passwd"
}

