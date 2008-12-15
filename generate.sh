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
exe="/bin/bash /bin/mount /bin/mknod /bin/mkdir /sbin/modprobe /sbin/udevd /sbin/udevadm /sbin/nash /bin/kill /sbin/pidof /bin/sleep"
lvmexe="/sbin/lvm"
# and some things that are nice for debugging
debugexe="/bin/ls /bin/cat /bin/ln /bin/ps /bin/grep /usr/bin/less"
# udev things we care about
udevexe="/lib/udev/vol_id"

# install base files
for binary in $exe $debugexe $udevexe $lvmexe ; do
  inst $binary $tmpdir
done

# FIXME: would be nice if we didn't have to know which rules to grab....
mkdir -p $tmpdir/lib/udev/rules.d
for rule in /lib/udev/rules.d/40-redhat* /lib/udev/rules.d/60-persistent-storage.rules /lib/udev/rules.d/61*edd* /lib/udev/rules.d/64* /lib/udev/rules.d/80* /lib/udev/rules.d/95* rules.d/*.rules ; do
  cp -v $rule $tmpdir/lib/udev/rules.d
done

# install our files
cp -v init $tmpdir/init
cp -v switch_root $tmpdir/sbin/switch_root

# FIXME: and some directory structure
mkdir -p $tmpdir/etc $tmpdir/proc $tmpdir/sys $tmpdir/sysroot

# FIXME: we don't install modules right now, but for the testing we're doing
# everything is already built-in

pushd $tmpdir >/dev/null
find . |cpio -H newc -o |gzip -9 > $INITRDOUT
popd >/dev/null
