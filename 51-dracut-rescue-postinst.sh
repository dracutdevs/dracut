#!/bin/bash

export LANG=C

KERNEL_VERSION="$1"
KERNEL_IMAGE="$2"

[[ -f /etc/os-release ]] && . /etc/os-release

if [[ ! -f /etc/machine-id ]] || [[ ! -s /etc/machine-id ]]; then
    systemd-machine-id-setup
fi

[[ -f /etc/machine-id ]] && read MACHINE_ID < /etc/machine-id

[[ $MACHINE_ID ]] || exit 1
[[ -f $KERNEL_IMAGE ]] || exit 1

KERNEL_HMAC="${KERNEL_IMAGE%/*}/.vmlinuz-${KERNEL_VERSION}.hmac"
INITRDFILE="/boot/initramfs-0-rescue-${MACHINE_ID}.img"
NEW_KERNEL_IMAGE="${KERNEL_IMAGE%/*}/vmlinuz-0-rescue-${MACHINE_ID}"
NEW_KERNEL_HMAC="${KERNEL_IMAGE%/*}/.vmlinuz-0-rescue-${MACHINE_ID}.hmac"

if [[ -f $INITRDFILE ]] && [[ -f $NEW_KERNEL_IMAGE ]]; then
   if [[ -f $NEW_KERNEL_HMAC ]]; then
      exit 0
   elif [[ ! -f '/usr/bin/sha512hmac' ]]; then
      exit 0
   fi
fi

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

if [[ ! -f $INITRDFILE ]]; then
    dracut --no-hostonly -a "rescue" "$INITRDFILE" "$KERNEL_VERSION"
    ((ret+=$?))
fi

if [[ ! -f $NEW_KERNEL_IMAGE ]]; then
    cp --reflink=auto "$KERNEL_IMAGE" "$NEW_KERNEL_IMAGE"
    if [[ ! -f $NEW_KERNEL_HMAC  ]] && [[ -f $KERNEL_HMAC ]]; then
        cp --reflink=auto "$KERNEL_HMAC" "$NEW_KERNEL_HMAC"
    fi
    ((ret+=$?))
fi

if [[ ! -f $NEW_KERNEL_HMAC ]] && [[ -f '/usr/bin/sha512hmac' ]]; then
    sha512hmac "$NEW_KERNEL_IMAGE" > "$NEW_KERNEL_HMAC"
    ((ret+=$?))
fi

if [[ ! $(grep -r Rescue /boot/) ]]; then
   new-kernel-pkg --install "$KERNEL_VERSION" --kernel-image "$NEW_KERNEL_IMAGE" --initrdfile "$INITRDFILE" --banner "$NAME $VERSION_ID Rescue $MACHINE_ID"
   ((ret+=$?))
fi

exit $ret
