#!/bin/bash --norc
kver=$(uname -r)

error() { echo "$@" >&2; }

usage () {
    [[ $1 = '-n' ]] && cmd=echo || cmd=error

    $cmd "usage: ${0##*/} [--version] [--help] [-v] [-f] [--preload <module>]"
    $cmd "       [--image-version] [--with=<module>]"
    $cmd "       [--nocompress]"
    $cmd "       <initrd-image> <kernel-version>"
    $cmd ""
    $cmd "       (ex: ${0##*/} /boot/initramfs-$kver.img $kver)"

    [[ $1 = '-n' ]] && exit 0
    exit 1
}

# Little helper function for reading args from the commandline.
# it automatically handles -a b and -a=b variants, and returns 1 if
# we need to shift $3.
read_arg() {
    # $1 = arg name
    # $2 = arg value
    # $3 = arg parameter
    local rematch='^[^=]*=(.*)$'
    if [[ $2 =~ $rematch ]]; then
        read "$1" <<< "${BASH_REMATCH[1]}"
    elif [[ $3 != -* ]]; then
        # Only read next arg if it not an arg itself.
        read "$1" <<< "$3"
        # There is no way to shift our callers args, so
        # return 1 to indicate they should do it instead.
        return 1
    fi
}

while (($# > 0)); do
    case ${1%%=*} in
        --with-usb) read_arg usbmodule "$@" || shift
            basicmodules="$basicmodules ${usbmodule:-usb-storage}"
            unset usbmodule;;
        --with-avail) read_arg modname "$@" || shift
            basicmodules="$basicmodules $modname";;
        --with) read_arg modname "$@" || shift
            basicmodules="$basicmodules $modname";;
        --version)
            echo "mkinitrd: dracut compatibility wrapper"
            exit 0;;
        -v|--verbose) dracut_args="${dracut_args} -v";;
        -f|--force) dracut_args="${dracut_args} -f";;
        --preload) read_arg modname "$@" || shift
            basicmodules="$basicmodules $modname";;
        --image-version) img_vers=yes;;
        --rootfs) read_arg rootfs "$@" || shift
            dracut_args="${dracut_args} --filesystems $rootfs";;
        --nocompress) dracut_args="$dracut_args --no-compress";;
        --help) usage -n;;
        --builtin) ;;
        --without*) ;;
        --without-usb) ;;
        --fstab*) ;;
        --ifneeded) ;;
        --omit-scsi-modules) ;;
        --omit-ide-modules) ;;
        --omit-raid-modules) ;;
        --omit-lvm-modules) ;;
        --omit-dmraid) ;;
        --allow-missing) ;;
        --net-dev*) ;;
        --noresume) ;;
        --rootdev*) ;;
        --thawdev*) ;;
        --rootopts*) ;;
        --root*) ;;
        --loopdev*) ;;
        --loopfs*) ;;
        --loopopts*) ;;
        --looppath*) ;;
        --dsdt*) ;;
        --bootchart) ;;
        *) if [[ ! $target ]]; then
            target=$1
            elif [[ ! $kernel ]]; then
            kernel=$1
            else
            usage
            fi;;
    esac
    shift
done

[[ $target && $kernel ]] || usage
[[ $img_vers ]] && target="$target-$kernel"

if [[ $basicmodules ]]; then
        dracut $dracut_args --add-drivers "$basicmodules" "$target" "$kernel"
else
        dracut $dracut_args "$target" "$kernel"
fi
