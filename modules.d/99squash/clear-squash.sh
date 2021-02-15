#!/bin/bash
mnt="/squash/root"
for dir in jsquash/root/*; do
	mnt="$mnt ${dir#$SQUASH_MNT}"
done
umount --lazy -- $mnt
