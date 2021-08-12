#!/usr/bin/env bash

BASEDIR=$(realpath $(dirname "$0"))
. $BASEDIR/image-init-lib.sh

# Base image to copy from
BOOT_IMAGE=$1 && shift
if [ ! -e "$BOOT_IMAGE" ]; then
	perror_exit "Image '$BOOT_IMAGE' not found"
else
	BOOT_IMAGE=$(realpath "$BOOT_IMAGE")
fi

mount_image $BOOT_IMAGE

IMAGE_MNT=$(get_image_mount_root $BOOT_IMAGE)

SRC=
while [ $# -gt 1 ]; do
	SRC="$SRC $IMAGE_MNT/$1"
	shift
done
DST=$1

cp -rv $SRC $DST
