#!/usr/bin/env bash

BASEDIR=$(realpath $(dirname "$0"))
. $BASEDIR/image-init-lib.sh

# Base image to build from
BOOT_IMAGE=$1
if [[ ! -e $BOOT_IMAGE ]]; then
	perror_exit "Image '$BOOT_IMAGE' not found"
else
	BOOT_IMAGE=$(realpath "$BOOT_IMAGE")
fi

mount_image $BOOT_IMAGE

shell_in_image $BOOT_IMAGE
