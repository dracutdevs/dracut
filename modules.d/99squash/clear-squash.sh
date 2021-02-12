#!/bin/bash
SQUASH_MNT_REC=/squash/mounts

mapfile -t SQUASH_MNTS < $SQUASH_MNT_REC

umount --lazy -- "${SQUASH_MNTS[@]}"
