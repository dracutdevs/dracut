#!/bin/bash --norc

error() {
    local NONL=""
    if [ "$1" == "-n" ]; then
        NONL="-n"
        shift
    fi
    echo $NONL "$@" > /dev/stderr
}

usage () {
    if [ "$1" == "-n" ]; then
        cmd=echo
    else
        cmd=error
    fi

    $cmd "usage: `basename $0` [--version] [--help] [-v] [-f] [--preload <module>]"
    $cmd "       [--image-version] [--with=<module>]"
    $cmd "       <initrd-image> <kernel-version>"
    $cmd ""
    $cmd "       (ex: `basename $0` /boot/initramfs-$(uname -r).img $(uname -r))"

    if [ "$1" == "-n" ]; then
        exit 0
    else
        exit 1
    fi
}


while [ $# -gt 0 ]; do
    case $1 in
        --with-usb*)
            if [ "$1" != "${1##--with-usb=}" ]; then
                usbmodule=${1##--with-usb=}
            else
                usbmodule="usb-storage"
            fi
            basicmodules="$basicmodules $usbmodule"
            unset usbmodule
            ;;
        --with-avail*)
            if [ "$1" != "${1##--with-avail=}" ]; then
                modname=${1##--with-avail=}
            else
                modname=$2
                shift
            fi

            basicmodules="$basicmodules $modname"
            ;;
        --with*)
            if [ "$1" != "${1##--with=}" ]; then
                modname=${1##--with=}
            else
                modname=$2
                shift
            fi

            basicmodules="$basicmodules $modname"
            ;;
        --version)
            echo "mkinitrd: dracut compatibility wrapper"
            exit 0
            ;;
        -v|--verbose)
            dracut_args="${dracut_args} -v"
            ;;
        -f)
            dracut_args="${dracut_args} -f"
            ;;
        --preload*)
            if [ "$1" != "${1##--preload=}" ]; then
                modname=${1##--preload=}
            else
                modname=$2
                shift
            fi
            basicmodules="$basicmodules $modname"
            ;;
        --image-version)
            img_vers=yes
            ;;
	--rootfs*)
            if [ "$1" != "${1##--rootfs=}" ]; then
                rootfs="${1##--rootfs=}"
            else
                rootfs="$2"
                shift
            fi
	    dracut_args="${dracut_args} --filesystems $rootfs"
	    ;;
        --builtin*) ;;
        --without*) ;;
        --without-usb) ;;
        --fstab*) ;;
        --nocompress) ;;
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
        --help)
            usage -n
            ;;
        *)
            if [ -z "$target" ]; then
                target=$1
            elif [ -z "$kernel" ]; then
                kernel=$1
            else
                usage
            fi
            ;;
    esac

    shift
done

if [ -z "$target" -o -z "$kernel" ]; then
    usage
fi

if [ -n "$img_vers" ]; then
    target="$target-$kernel"
fi

if [ -n "$basicmodules" ]; then
	dracut -H $dracut_args --add-drivers "$basicmodules" "$target" "$kernel"
else
	dracut -H $dracut_args "$target" "$kernel"
fi

# vim:ts=8:sw=4:sts=4:et
