#!/bin/sh
PATH=/bin:/sbin

# Basic mounts for mounting a squash image
mkdir /proc /sys /dev /run
mount -t proc -o nosuid,noexec,nodev proc /proc
mount -t sysfs -o nosuid,noexec,nodev sysfs /sys
mount -t devtmpfs -o mode=755,noexec,nosuid,strictatime devtmpfs /dev
mount -t tmpfs -o mode=755,nodev,nosuid,strictatime tmpfs /run

# Load required modules
modprobe loop
modprobe squashfs
modprobe overlay

# Mount the squash image
mount -t ramfs ramfs /squash
mkdir -p /squash/root /squash/overlay/upper /squash/overlay/work
mount -t squashfs -o ro,loop /squash-root.img /squash/root

# Setup new root overlay
mkdir /newroot
mount -t overlay overlay -o lowerdir=/squash/root,upperdir=/squash/overlay/upper,workdir=/squash/overlay/work/ /newroot/

# Move all mount points to new root to prepare chroot
mount --move /squash /newroot/squash

# Jump to new root and clean setup files
SYSTEMD_IN_INITRD=lenient exec switch_root /newroot /init
