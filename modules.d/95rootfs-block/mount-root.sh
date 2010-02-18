#!/bin/sh

. /lib/dracut-lib.sh

filter_rootopts() {
    rootopts=$1
    # strip ro and rw options
    local OLDIFS="$IFS"
    IFS=,
    set -- $rootopts
    IFS="$OLDIFS"
    local v
    while [ $# -gt 0 ]; do
        case $1 in
            rw|ro);;
	    defaults);;
            *)
                v="$v,${1}";;
        esac
        shift
    done
    rootopts=${v#,}
    echo $rootopts
}

if [ -n "$root" -a -z "${root%%block:*}" ]; then
    mount -t ${fstype:-auto} -o "$rflags" "${root#block:}" "$NEWROOT" \
        && ROOTFS_MOUNTED=yes 

    if ! getarg rd_NO_FSTAB \
      && ! getarg rootflags \
      && [ -f "$NEWROOT/etc/fstab" ] \
      && ! [ -L "$NEWROOT/etc/fstab" ]; then
        # if $NEWROOT/etc/fstab contains special mount options for 
        # the root filesystem,
        # remount it with the proper options
	rootfs="auto"
	rootopts="defaults"
	while read dev mp fs opts rest; do 
            # skip comments
            [ "${dev%%#*}" != "$dev" ] && continue
            
            if [ "$mp" = "/" ]; then
		rootfs=$fs
		rootopts=$opts
		break
            fi
	done < "$NEWROOT/etc/fstab"

	rootopts=$(filter_rootopts $rootopts)

	if [ -n "$rootopts" ]; then
            umount $NEWROOT
            info "Remounting ${root#block:} with -o $rootopts,$rflags"
            mount -t "$rootfs" -o "$rflags","$rootopts" \
                "${root#block:}" "$NEWROOT" 2>&1 | vinfo
	fi
    fi
fi
