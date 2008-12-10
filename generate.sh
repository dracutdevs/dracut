#/bin/bash
# Simple script that creates the tree to use for a new initrd
# note that this is not intended to be pretty, nice or anything
# of the sort.  the important thing is working


source /usr/libexec/initrd-functions

INITRDOUT=$1
if [ -z "$INITRDOUT" ]; then
    echo "Please specify an initrd file to output"
    exit 1
fi

tmpdir=$(mktemp -d)

# executables that we have to have
exe="/bin/bash /bin/mount /bin/mknod /bin/mkdir /sbin/modprobe /sbin/udevd /sbin/udevadm /sbin/nash"
# and some things that are nice for debugging
debugexe="/bin/ls /bin/cat /bin/ln /bin/ps /bin/grep /usr/bin/less"

# install base files
for binary in $exe $debugexe ; do
  inst $binary $tmpdir
done

# install our files
inst init $tmpdir/init
inst switch_root $tmpdir/sbin/switch_root

# FIXME: we don't install modules right now, but for the testing we're doing
# everything is already built-in

pushd $tmpdir >/dev/null
find . |cpio -H newc -o |gzip -9 > $INITRDOUT
popd >/dev/null
