#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

export LANG=C

KERNEL_VERSION="$1"
KERNEL_IMAGE="$2"

[[ -f /etc/os-release ]] && . /etc/os-release
[[ -f /etc/machine-id ]] && read MACHINE_ID < /etc/machine-id

INITRDFILE="/boot/initramfs-${MACHINE_ID}-rescue.img"
[[ -f $INITRDFILE ]] && exit 0

dropindirs_sort()
{
    suffix=$1; shift
    args=("$@")
    files=$(
        while (( $# > 0 )); do
            for i in ${1}/*${suffix}; do
                [[ -f $i ]] && echo ${i##*/}
            done
            shift
        done | sort -Vu
    )

    for f in $files; do
        for d in "${args[@]}"; do
            if [[ -f "$d/$f" ]]; then
                echo "$d/$f"
                continue 2
            fi
        done
    done
}

# source our config dir
for f in $(dropindirs_sort ".conf" "/etc/dracut.conf.d" "/usr/lib/dracut/dracut.conf.d"); do
    [[ -e $f ]] && . "$f"
done

[[ $dracut_rescue_image != "yes" ]] && exit 0

dracut --no-hostonly  -a "rescue" "$INITRDFILE" "$KERNEL_VERSION"
((ret+=$?))

cp "$KERNEL_IMAGE" "${KERNEL_IMAGE%/*}/vmlinuz-${MACHINE_ID}-rescue"
((ret+=$?))

KERNEL_IMAGE="${KERNEL_IMAGE%/*}/vmlinuz-${MACHINE_ID}-rescue"

new-kernel-pkg --install "$KERNEL_VERSION" --kernel-image "$KERNEL_IMAGE" --initrdfile "$INITRDFILE" --banner "$PRETTY_NAME Rescue"

((ret+=$?))

exit $ret
