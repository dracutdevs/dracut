#!/bin/sh

# shellcheck disable=SC2154
if [ "${root%%:*}" = "block" ]; then
    {
        printf 'KERNEL=="%s", SYMLINK+="root"\n' \
            "${root#block:/dev/}"
        printf 'SYMLINK=="%s", SYMLINK+="root"\n' \
            "${root#block:/dev/}"
    } >> /etc/udev/rules.d/99-root.rules

    # shellcheck disable=SC2016
    # shellcheck disable=SC2154
    printf '[ -e "%s" ] && { ln -s "%s" /dev/root 2>/dev/null; rm "$job"; }\n' \
        "${root#block:}" "${root#block:}" > "$hookdir"/initqueue/settled/blocksymlink.sh

    wait_for_dev "${root#block:}"
fi
