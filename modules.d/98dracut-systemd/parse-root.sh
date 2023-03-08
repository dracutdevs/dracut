#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

root=$(getarg root=)
case "${root#block:}" in
    LABEL=* | UUID=* | PARTUUID=* | PARTLABEL=*)
        root="block:$(label_uuid_to_dev "$root")"
        rootok=1
        ;;
    /dev/nfs | /dev/root) # ignore legacy
        ;;
    /dev/*)
        root="block:${root}"
        rootok=1
        ;;
esac

if [ "$rootok" = "1" ]; then
    root_dev="${root#block:}"
    root_name="$(str_replace "$root_dev" '/' '\x2f')"
    if ! [ -e "$hookdir/initqueue/finished/devexists-${root_name}.sh" ]; then

        # If a LUKS device needs unlocking via systemd in the initrd, assume
        # it's for the root device. In that case, don't block on it if it's
        # after remote-fs-pre.target since the initqueue is ordered before it so
        # it will never actually show up (think Tang-pinned rootfs).
        cat > "$hookdir/initqueue/finished/devexists-${root_name}.sh" << EOF
if ! grep -q After=remote-fs-pre.target /run/systemd/generator/systemd-cryptsetup@*.service 2>/dev/null; then
    [ -e "$root_dev" ]
fi
EOF
        {
            printf '[ -e "%s" ] || ' "$root_dev"
            printf 'warn "\"%s\" does not exist"\n' "$root_dev"
        } >> "$hookdir/emergency/80-${root_name}.sh"
    fi
fi
