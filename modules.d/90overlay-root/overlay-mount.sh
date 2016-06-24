#!/bin/sh

# make a read-only nfsroot writeable by using overlayfs
# the nfsroot is already mounted to $NEWROOT
# add the parameter rd.root.overlay to the kernel to activate this feature

. /lib/dracut-lib.sh

if ! getargbool 0 rd.root.overlay -d rootovl; then
    return
fi

upperdir=/run/overlay-root/upper
lowerdir=/run/overlay-root/lower
workdir=/run/overlay-root/work

mkdir -p "$upperdir" "$lowerdir" "$workdir"

# Move root
mount --move "$NEWROOT" "$lowerdir"

# Create tmpfs
mount -t tmpfs -o mode=0755 tmpfs "$upperdir"
mount -t tmpfs -o mode=0755 tmpfs "$workdir"

# Merge both to new Filesystem
mount -t overlay -o "lowerdir=$lowerdir,upperdir=$upperdir,workdir=$workdir,redirect_dir=on,metacopy=on,default_permissions" overlay "$NEWROOT"

# Let filesystems survive pivot
mkdir -p "$NEWROOT$upperdir" "$NEWROOT$lowerdir" "$NEWROOT$workdir"
mount --move "$upperdir" "$NEWROOT$upperdir"
mount --move "$lowerdir" "$NEWROOT$lowerdir"
mount --move "$workdir" "$NEWROOT$workdir"
