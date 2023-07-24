#!/bin/bash

check() {
    require_binaries mksquashfs unsquashfs || return 1
    require_kernel_modules squashfs loop overlay || return 1

    return 255
}

depends() {

    if find_binary busybox &> /dev/null \
        && ! strstr " $omit_dracutmodules " " busybox "; then
        echo "busybox"
    fi
    echo "systemd-initrd"
    return 0
}

install() {

    # Enroll module for postprocessing.
    # shellcheck disable=SC2154
    mods_to_postprocess+=" squash:$moddir@installpost@ "

}

installpost() {
    # shellcheck disable=SC2154
    readonly squash_dir="$initdir/squash/root"
    readonly squash_img="$initdir/squash-root.img"
    mkdir -p "$squash_dir"
    dinfo "*** Install squash loader ***"

    # Move everything under $initdir except $squash_dir
    # itself into squash image
    for i in "$initdir"/*; do
        [[ $squash_dir == "$i"/* ]] || mv "$i" "$squash_dir"/
    done

    # Create mount points for squash loader
    mkdir -p "$initdir"/squash/
    mkdir -p "$squash_dir"/squash/

    # Copy /dracut/ directory files out of the squash image directory
    # so dracut rebuild and lsinitrd can work.
    for file in "$squash_dir"/usr/lib/dracut/*; do
        [[ -f $file ]] || continue
        DRACUT_RESOLVE_DEPS=1 dracutsysrootdir="$squash_dir" inst "${file#"$squash_dir"}"
    done

    # Install required modules and binaries for the squash image init script.
    if find_binary busybox; then
        inst busybox /usr/bin/busybox
        for _i in sh echo mount modprobe mkdir switch_root grep umount; do
            ln_r /usr/bin/busybox /usr/bin/$_i
        done
    else
        DRACUT_RESOLVE_DEPS=1 inst_multiple sh mount modprobe mkdir switch_root grep umount

        # libpthread workaround: pthread_cancel wants to dlopen libgcc_s.so
        inst_libdir_file -o "libgcc_s.so*"

        # FIPS workaround for Fedora/RHEL: libcrypto needs libssl when FIPS is enabled
        [[ $DRACUT_FIPS_MODE ]] && inst_libdir_file -o "libssl.so*"
    fi

    hostonly="" instmods "loop" "squashfs" "overlay"
    dracut_kernel_post

    # Install squash image init script.
    ln_r /usr/bin /bin
    ln_r /usr/sbin /sbin
    inst_simple "$moddir"/init-squash.sh /init

    # make sure that library links are correct and up to date for squash loader
    build_ld_cache
}

postprocess() {

    # shellcheck disable=SC2154
    [[ $action == installpost ]] && {
        installpost
        return 0
    }

    dinfo "*** Squashing the files inside the initramfs ***"
    declare squash_compress_arg
    if [[ $squash_compress ]]; then
        # shellcheck disable=SC2086
        if ! mksquashfs /dev/null "$DRACUT_TMPDIR"/.squash-test.img -no-progress -comp $squash_compress &> /dev/null; then
            dwarn "mksquashfs doesn't support compressor '$squash_compress', falling back to default compressor."
        else
            squash_compress_arg="$squash_compress"
        fi
    fi

    # shellcheck disable=SC2086
    if ! mksquashfs "$squash_dir" "$squash_img" \
        -no-xattrs -no-exports -noappend -no-recovery -always-use-fragments \
        -no-progress ${squash_compress_arg:+-comp $squash_compress_arg} 1> /dev/null; then
        dfatal "Failed making squash image"
        exit 1
    fi

    rm -rf "$squash_dir"
    dinfo "*** Squashing the files inside the initramfs done ***"

    # Skip initramfs compress
    export compress="cat"

}
