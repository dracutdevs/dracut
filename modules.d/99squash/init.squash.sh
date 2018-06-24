#!/bin/sh
PATH=/bin:/sbin
SQUASH_IMG=/init.squash.sqsh
SQUASH_MNT=/dev/.squash-initramfs
SQUASH_INIT_ROOT=/dev/.squash-init-root

# Following mount points are neccessary for mounting a squash image
mount -t proc -o nosuid,noexec,nodev proc /proc >/dev/null
mount -t sysfs -o nosuid,noexec,nodev sysfs /sys >/dev/null
mount -t devtmpfs -o mode=0755,noexec,nosuid,strictatime devtmpfs /dev >/dev/null

# Need a loop device backend, and squashfs module
modprobe loop
if [[ $? != 0 ]]; then
    echo "Unable to setup loop device"
    exit 1
fi

modprobe squashfs
if [[ $? != 0 ]]; then
    echo "Unable to setup squashfs"
    exit 1
fi

mkdir -m 0755 -p ${SQUASH_MNT}
mkdir -m 0755 -p ${SQUASH_INIT_ROOT}
mount -t squashfs -o ro,loop $SQUASH_IMG $SQUASH_MNT

# Mount and replace
if [[ $? != 0 ]]; then
    echo "Unable to mount squashed initramfs image"
    exit 1
fi

# Close all fds before exec
fd_path=/proc/self/fd
for fd in ${fd_path}/*; do
    fd=${fd#${fd_path}/}
    [[ $fd -gt 2 ]] && eval "exec ${fd}>&-"
done

# Create a bind mount of old root so symlinks inside squash image
# can resolve
mount --bind --make-private / ${SQUASH_INIT_ROOT}

mount --bind ${SQUASH_MNT}/etc /etc
mount --bind ${SQUASH_MNT}/usr /usr

exec /init.orig

echo "Something went wrong when trying to start origin init executable"
exit 1
