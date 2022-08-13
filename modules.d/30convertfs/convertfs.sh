#!/bin/sh

type ismounted > /dev/null 2>&1 || . /lib/dracut-lib.sh

ROOT="$1"

if ! [ -d "$ROOT" ]; then
    echo "Usage: $0 <rootdir>"
    exit 1
fi

if [ "$ROOT" -ef / ]; then
    echo "Can't convert the running system."
    echo "Please boot with 'rd.convertfs' on the kernel command line,"
    echo "to update with the help of the initramfs,"
    echo "or run this script from a rescue system."
    exit 1
fi

while ! [ "$ROOT" = "${ROOT%/}" ]; do
    ROOT=${ROOT%/}
done

if [ -e "$ROOT"/var/run ] && ! [ -L "$ROOT"/var/run ]; then
    echo "Converting /var/run to symlink"
    mv -f "$ROOT"/var/run "$ROOT"/var/run.runmove~
    ln -sfn ../run "$ROOT"/var/run
fi

if [ -e "$ROOT"/var/lock ] && ! [ -L "$ROOT"/var/lock ]; then
    echo "Converting /var/lock to symlink"
    mv -f "$ROOT"/var/lock "$ROOT"/var/lock.lockmove~
    ln -sfn ../run/lock "$ROOT"/var/lock
fi

needconvert() {
    for dir in "$ROOT/bin" "$ROOT/sbin" "$ROOT/lib" "$ROOT/lib64"; do
        [ -e "$dir" ] && ! [ -L "$dir" ] && return 0
    done
    return 1
}

if ! [ -e "$ROOT/usr/bin" ]; then
    echo "$ROOT/usr/bin does not exist!"
    echo "Make sure, the kernel command line has enough information"
    echo "to mount /usr (man dracut.cmdline)"
    exit 1
fi

if ! needconvert; then
    echo "Your system is already converted."
    exit 0
fi

testfile="$ROOT/.usrmovecheck$$"
rm -f -- "$testfile"
: > "$testfile"
if [ ! -e "$testfile" ]; then
    echo "Cannot write to $ROOT/"
    exit 1
fi
rm -f -- "$testfile"

testfile="$ROOT/usr/.usrmovecheck$$"
rm -f -- "$testfile"
: > "$testfile"
if [ ! -e "$testfile" ]; then
    echo "Cannot write to $ROOT/usr/"
    exit 1
fi
rm -f -- "$testfile"

find_mount() {
    local dev wanted_dev
    wanted_dev="$(readlink -e -q "$1")"
    while read -r dev _ || [ -n "$dev" ]; do
        [ "$dev" = "$wanted_dev" ] && echo "$dev" && return 0
    done < /proc/mounts
    return 1
}

# clean up after ourselves no matter how we die.
cleanup() {
    echo "Something failed. Move back to the original state"
    for dir in "$ROOT/bin" "$ROOT/sbin" "$ROOT/lib" "$ROOT/lib64" \
        "$ROOT/usr/bin" "$ROOT/usr/sbin" "$ROOT/usr/lib" \
        "$ROOT/usr/lib64"; do
        [ -d "${dir}.usrmove-new" ] && rm -rf -- "${dir}.usrmove-new"
        if [ -d "${dir}.usrmove-old" ]; then
            mv "$dir" "${dir}.del~"
            mv "${dir}.usrmove-old" "$dir"
            rm -rf -- "${dir}.del~"
        fi
    done
}

trap 'ret=$?; [ $ret -ne 0 ] && cleanup; exit $ret;' EXIT
trap 'exit 1;' INT

ismounted "$ROOT/usr" || CP_HARDLINK="-l"

set -e

# merge / and /usr in new dir in /usr
for dir in bin sbin lib lib64; do
    rm -rf -- "$ROOT/usr/${dir}.usrmove-new"
    [ -L "$ROOT/$dir" ] && continue
    [ -d "$ROOT/$dir" ] || continue
    echo "Make a copy of \`$ROOT/usr/$dir'."
    [ -d "$ROOT/usr/$dir" ] \
        && cp -ax -l "$ROOT/usr/$dir" "$ROOT/usr/${dir}.usrmove-new"
    echo "Merge the copy with \`$ROOT/$dir'."
    [ -d "$ROOT/usr/${dir}.usrmove-new" ] \
        || mkdir -p "$ROOT/usr/${dir}.usrmove-new"
    cp -axT $CP_HARDLINK --backup --suffix=.usrmove~ "$ROOT/$dir" "$ROOT/usr/${dir}.usrmove-new"
    echo "Clean up duplicates in \`$ROOT/usr/$dir'."
    # delete all symlinks that have been backed up
    find "$ROOT/usr/${dir}.usrmove-new" -type l -name '*.usrmove~' -delete || :
    # replace symlink with backed up binary
    find "$ROOT/usr/${dir}.usrmove-new" \
        -type f \
        -name '*.usrmove~' \
        -exec sh -c 'p="$1";o=${p%.usrmove~};
                     [ -L "$o" ] && mv -f "$p" "$o"' _ "{}" \; || :
done
# switch over merged dirs in /usr
for dir in bin sbin lib lib64; do
    [ -d "$ROOT/usr/${dir}.usrmove-new" ] || continue
    echo "Switch to new \`$ROOT/usr/$dir'."
    rm -fr -- "$ROOT/usr/${dir}.usrmove-old"
    mv "$ROOT/usr/$dir" "$ROOT/usr/${dir}.usrmove-old"
    mv "$ROOT/usr/${dir}.usrmove-new" "$ROOT/usr/$dir"
done

# replace dirs in / with links to /usr
for dir in bin sbin lib lib64; do
    [ -L "$ROOT/$dir" ] && continue
    [ -d "$ROOT/$dir" ] || continue
    echo "Create \`$ROOT/$dir' symlink."
    rm -fr -- "$ROOT/${dir}.usrmove-old" || :
    mv "$ROOT/$dir" "$ROOT/${dir}.usrmove-old"
    ln -sfn usr/$dir "$ROOT/$dir"
done

echo "Clean up backup files."
# everything seems to work; cleanup
for dir in bin sbin lib lib64; do
    # if we get killed in the middle of "rm -rf", ensure not to leave
    # an incomplete directory, which is moved back by cleanup()
    [ -d "$ROOT/usr/${dir}.usrmove-old" ] \
        && mv "$ROOT/usr/${dir}.usrmove-old" "$ROOT/usr/${dir}.usrmove-old~"
    [ -d "$ROOT/${dir}.usrmove-old" ] \
        && mv "$ROOT/${dir}.usrmove-old" "$ROOT/${dir}.usrmove-old~"
done

for dir in bin sbin lib lib64; do
    if [ -d "$ROOT/usr/${dir}.usrmove-old~" ]; then
        rm -rf -- "$ROOT/usr/${dir}.usrmove-old~"
    fi

    if [ -d "$ROOT/${dir}.usrmove-old~" ]; then
        rm -rf -- "$ROOT/${dir}.usrmove-old~"
    fi
done

for dir in lib lib64; do
    [ -d "$ROOT/$dir" ] || continue
    for lib in "$ROOT"/usr/"${dir}"/lib*.so*.usrmove~; do
        [ -f "$lib" ] || continue
        mv "$lib" "$(echo "$lib" | sed '\.so/_so/')"
    done
done

set +e

echo "Run ldconfig."
ldconfig -r "$ROOT"

if [ -f "$ROOT"/etc/selinux/config ]; then
    # shellcheck disable=SC1090
    . "$ROOT"/etc/selinux/config
fi

if [ -n "$(command -v setfiles)" ] && [ "$SELINUX" != "disabled" ] && [ -f /etc/selinux/"${SELINUXTYPE}"/contexts/files/file_contexts ]; then
    echo "Fixing SELinux labels"
    setfiles -r "$ROOT" -p /etc/selinux/"${SELINUXTYPE}"/contexts/files/file_contexts "$ROOT"/sbin "$ROOT"/bin "$ROOT"/lib "$ROOT"/lib64 "$ROOT"/usr/lib "$ROOT"/usr/lib64 "$ROOT"/etc/ld.so.cache "$ROOT"/var/cache/ldconfig || :
fi

echo "Done."
exit 0
