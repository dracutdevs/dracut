#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# shellcheck disable=SC2034
TEST_DESCRIPTION="test conf change from space-separated lists to arrays"

test_check() {
    return 0
}

test_setup() {
    TEST_CONF="$TESTDIR/dracut-test.conf"
    export TEST_CONF
    TEST_CONF_DIR=$(mktemp -d -p "$TESTDIR") || return 1
    export TEST_CONF_DIR
    TEST_INITRD="$TESTDIR/initramfs"
    export TEST_INITRD
    TEST_ITEMS_DIR=$(mktemp -d -p "/") || return 1
    export TEST_ITEMS_DIR
    dracutbasedir="$basedir"
    export dracutbasedir
    return 0
}

build_with_test_conf() {
    "$basedir"/dracut.sh -f \
        --conf "$TEST_CONF" \
        --confdir "$TEST_CONF_DIR" \
        --no-hostonly --no-hostonly-cmdline \
        "$@" \
        "$TEST_INITRD" \
        2>&1
}

test_run() {
    set -x

    # dracutmodules

    # old style
    cat << EOF > "$TEST_CONF"
dracutmodules+=" rescue debug terminfo "
EOF
    build_with_test_conf --no-kernel || return 1
    dracut_modules=$("$basedir"/lsinitrd.sh -m "$TEST_INITRD")
    echo "$dracut_modules" | grep -q '^rescue' || return 1
    echo "$dracut_modules" | grep -q '^debug' || return 1
    echo "$dracut_modules" | grep -q '^terminfo' || return 1
    echo "$dracut_modules" | grep -q '^base' && return 1

    # new style
    cat << EOF > "$TEST_CONF"
dracutmodules+=( rescue debug terminfo )
EOF
    build_with_test_conf --no-kernel || return 1
    dracut_modules=$("$basedir"/lsinitrd.sh -m "$TEST_INITRD")
    echo "$dracut_modules" | grep -q '^rescue' || return 1
    echo "$dracut_modules" | grep -q '^debug' || return 1
    echo "$dracut_modules" | grep -q '^terminfo' || return 1
    echo "$dracut_modules" | grep -q '^base' && return 1

    # mix conf file and command line arguments
    cat << EOF > "$TEST_CONF"
dracutmodules+=( rescue debug )
EOF
    build_with_test_conf --no-kernel \
        --modules "bash terminfo" \
        || return 1
    dracut_modules=$("$basedir"/lsinitrd.sh -m "$TEST_INITRD")
    echo "$dracut_modules" | grep -q '^rescue' && return 1
    echo "$dracut_modules" | grep -q '^debug' && return 1
    echo "$dracut_modules" | grep -q '^bash' || return 1
    echo "$dracut_modules" | grep -q '^terminfo' || return 1

    # add_dracutmodules
    # force_add_dracutmodules
    # omit_dracutmodules

    # old style
    cat << EOF > "$TEST_CONF"
add_dracutmodules+=" rescue debug "
force_add_dracutmodules+=" kernel-network-modules "
omit_dracutmodules+=" kernel-modules-extra terminfo shutdown "
EOF
    build_with_test_conf --no-kernel || return 1
    dracut_modules=$("$basedir"/lsinitrd.sh -m "$TEST_INITRD")
    echo "$dracut_modules" | grep -q '^rescue' || return 1
    echo "$dracut_modules" | grep -q '^debug' || return 1
    echo "$dracut_modules" | grep -q '^kernel-network-modules' || return 1
    echo "$dracut_modules" | grep -q '^kernel-modules-extra' && return 1
    echo "$dracut_modules" | grep -q '^terminfo' && return 1
    echo "$dracut_modules" | grep -q '^shutdown' && return 1

    # new style
    cat << EOF > "$TEST_CONF"
add_dracutmodules+=( rescue debug )
force_add_dracutmodules+=( kernel-network-modules )
omit_dracutmodules+=( kernel-modules-extra terminfo shutdown )
EOF
    build_with_test_conf --no-kernel || return 1
    dracut_modules=$("$basedir"/lsinitrd.sh -m "$TEST_INITRD")
    echo "$dracut_modules" | grep -q '^rescue' || return 1
    echo "$dracut_modules" | grep -q '^debug' || return 1
    echo "$dracut_modules" | grep -q '^kernel-network-modules' || return 1
    echo "$dracut_modules" | grep -q '^kernel-modules-extra' && return 1
    echo "$dracut_modules" | grep -q '^terminfo' && return 1
    echo "$dracut_modules" | grep -q '^shutdown' && return 1

    # mix conf file and command line arguments
    cat << EOF > "$TEST_CONF"
add_dracutmodules+=( rescue )
force_add_dracutmodules+=( kernel-network-modules )
omit_dracutmodules+=( kernel-modules-extra )
EOF
    build_with_test_conf --no-kernel \
        --add debug \
        --force-add fs-lib \
        --omit "terminfo shutdown" \
        || return 1
    dracut_modules=$("$basedir"/lsinitrd.sh -m "$TEST_INITRD")
    echo "$dracut_modules" | grep -q '^rescue' || return 1
    echo "$dracut_modules" | grep -q '^debug' || return 1
    echo "$dracut_modules" | grep -q '^kernel-network-modules' || return 1
    echo "$dracut_modules" | grep -q '^fs-lib' || return 1
    echo "$dracut_modules" | grep -q '^kernel-modules-extra' && return 1
    echo "$dracut_modules" | grep -q '^terminfo' && return 1
    echo "$dracut_modules" | grep -q '^shutdown' && return 1

    # drivers
    # filesystems

    # old style
    cat << EOF > "$TEST_CONF"
drivers+=" ata_generic cdrom soundcore "
filesystems+=" xfs btrfs ext4 "
EOF
    build_with_test_conf --modules debug --kernel-only || return 1
    kernel_drivers=$("$basedir"/lsinitrd.sh "$TEST_INITRD" | grep "\.ko")
    echo "$kernel_drivers" | grep -q 'ata_generic\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'libata\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'scsi_mod\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'cdrom\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'soundcore\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'dm-multipath\.ko' && return 1
    echo "$kernel_drivers" | grep -q 'xfs\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'btrfs\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'ext4\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'jfs\.ko' && return 1

    # new style
    cat << EOF > "$TEST_CONF"
drivers+=( ata_generic cdrom soundcore )
filesystems+=( xfs btrfs ext4 )
EOF
    build_with_test_conf --modules debug --kernel-only || return 1
    kernel_drivers=$("$basedir"/lsinitrd.sh "$TEST_INITRD" | grep "\.ko")
    echo "$kernel_drivers" | grep -q 'ata_generic\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'libata\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'scsi_mod\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'cdrom\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'soundcore\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'dm-multipath\.ko' && return 1
    echo "$kernel_drivers" | grep -q 'xfs\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'btrfs\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'ext4\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'jfs\.ko' && return 1

    # mix conf file and command line arguments
    cat << EOF > "$TEST_CONF"
drivers+=( cdrom soundcore )
filesystems+=( xfs btrfs )
EOF
    build_with_test_conf --modules debug --kernel-only \
        --drivers "ata_generic dm-multipath" \
        --filesystems "ext4 jfs" \
        || return 1
    kernel_drivers=$("$basedir"/lsinitrd.sh "$TEST_INITRD" | grep "\.ko")
    echo "$kernel_drivers" | grep -q 'cdrom\.ko' && return 1
    echo "$kernel_drivers" | grep -q 'soundcore\.ko' && return 1
    echo "$kernel_drivers" | grep -q 'ata_generic\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'scsi_mod\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'libata\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'dm-multipath\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'xfs\.ko' && return 1
    echo "$kernel_drivers" | grep -q 'btrfs\.ko' && return 1
    echo "$kernel_drivers" | grep -q 'ext4\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'jfs\.ko' || return 1

    # add_drivers
    # force_drivers
    # omit_drivers

    # old style
    cat << EOF > "$TEST_CONF"
add_drivers+=" cdrom soundcore "
force_drivers+=" xor ata_generic "
omit_drivers+=" libata "
EOF
    build_with_test_conf --modules debug --kernel-only || return 1
    kernel_drivers=$("$basedir"/lsinitrd.sh "$TEST_INITRD" | grep "\.ko")
    echo "$kernel_drivers" | grep -q 'cdrom\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'soundcore\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'xor\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'ata_generic\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'scsi_mod\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'libata\.ko' && return 1

    # new style
    cat << EOF > "$TEST_CONF"
add_drivers+=( cdrom soundcore )
force_drivers+=( xor ata_generic )
omit_drivers+=( libata )
EOF
    build_with_test_conf --modules debug --kernel-only || return 1
    kernel_drivers=$("$basedir"/lsinitrd.sh "$TEST_INITRD" | grep "\.ko")
    echo "$kernel_drivers" | grep -q 'cdrom\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'soundcore\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'xor\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'ata_generic\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'scsi_mod\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'libata\.ko' && return 1

    # mix conf file and command line arguments
    cat << EOF > "$TEST_CONF"
add_drivers+=( cdrom )
force_drivers+=( xor )
omit_drivers+=( libata )
EOF
    build_with_test_conf --modules debug --kernel-only \
        --add-drivers soundcore \
        --force-drivers "ata_generic dm-multipath" \
        --omit-drivers scsi_mod \
        || return 1
    kernel_drivers=$("$basedir"/lsinitrd.sh "$TEST_INITRD" | grep "\.ko")
    echo "$kernel_drivers" | grep -q 'cdrom\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'soundcore\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'xor\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'ata_generic\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'dm-multipath\.ko' || return 1
    echo "$kernel_drivers" | grep -q 'libata\.ko' && return 1
    echo "$kernel_drivers" | grep -q 'scsi_mod\.ko' && return 1

    # install_items
    # install_optional_items
    # libdirs
    # fscks

    test_item_1=$(mktemp -p "$TEST_ITEMS_DIR") || return 1
    test_item_2=$(mktemp -p "$TEST_ITEMS_DIR") || return 1
    test_item_3=$(mktemp -p "$TEST_ITEMS_DIR") || return 1
    test_item_4=$(mktemp -p "$TEST_ITEMS_DIR") || return 1
    test_item_5=$(mktemp -p "$TEST_ITEMS_DIR") || return 1
    test_item_6="$TEST_ITEMS_DIR/this-file-should-not-exist"
    test_libdir_1=$(mktemp -d -p "$TEST_ITEMS_DIR") || return 1
    test_libdir_2=$(mktemp -d -p "$TEST_ITEMS_DIR") || return 1
    test_libdir_3=$(mktemp -d -p "$TEST_ITEMS_DIR") || return 1
    test_fsck_1=$(mktemp -p "$TEST_ITEMS_DIR") || return 1
    test_fsck_2=$(mktemp -p "$TEST_ITEMS_DIR") || return 1
    test_fsck_3=$(mktemp -p "$TEST_ITEMS_DIR") || return 1

    # old style
    cat << EOF > "$TEST_CONF"
install_items+=" $test_item_1 $test_item_2 $test_item_3 "
install_optional_items+=" $test_item_4 $test_item_5 $test_item_6 "
libdirs+=" $test_libdir_1 $test_libdir_2 $test_libdir_3 "
fscks+=" $test_fsck_1 $test_fsck_2 $test_fsck_3 "
EOF
    build_with_test_conf --modules fs-lib --no-kernel || return 1
    initrd_content=$("$basedir"/lsinitrd.sh "$TEST_INITRD" | grep -v "Arguments:" | grep "${TEST_ITEMS_DIR:1}")
    echo "$initrd_content" | grep -q "${test_item_1:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_2:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_3:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_4:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_5:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_6:1}" && return 1

    echo "$initrd_content" | grep -q "${test_libdir_1:1}" || return 1
    echo "$initrd_content" | grep -q "${test_libdir_2:1}" || return 1
    echo "$initrd_content" | grep -q "${test_libdir_3:1}" || return 1
    echo "$initrd_content" | grep -q "${test_fsck_1:1}" || return 1
    echo "$initrd_content" | grep -q "${test_fsck_2:1}" || return 1
    echo "$initrd_content" | grep -q "${test_fsck_3:1}" || return 1

    # new style
    mv "$test_item_1" "$TEST_ITEMS_DIR/a file with spaces" \
        && test_item_1="$TEST_ITEMS_DIR/a file with spaces" \
        || return 1
    mv "$test_item_4" "$TEST_ITEMS_DIR/other file with spaces" \
        && test_item_4="$TEST_ITEMS_DIR/other file with spaces" \
        || return 1
    mv "$test_libdir_1" "$TEST_ITEMS_DIR/lib dir with spaces" \
        && test_libdir_1="$TEST_ITEMS_DIR/lib dir with spaces" \
        || return 1

    cat << EOF > "$TEST_CONF"
install_items+=( "$test_item_1" $test_item_2 $test_item_3 )
install_optional_items+=( "$test_item_4" $test_item_5 $test_item_6 )
libdirs+=( "$test_libdir_1" $test_libdir_2 $test_libdir_3 )
fscks+=( $test_fsck_1 $test_fsck_2 $test_fsck_3 )
EOF
    build_with_test_conf --modules fs-lib --no-kernel || return 1
    initrd_content=$("$basedir"/lsinitrd.sh "$TEST_INITRD" | grep -v "Arguments:" | grep "${TEST_ITEMS_DIR:1}")
    echo "$initrd_content" | grep -q "${test_item_1:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_2:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_3:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_4:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_5:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_6:1}" && return 1
    echo "$initrd_content" | grep -q "${test_libdir_1:1}" || return 1
    echo "$initrd_content" | grep -q "${test_libdir_2:1}" || return 1
    echo "$initrd_content" | grep -q "${test_libdir_3:1}" || return 1
    echo "$initrd_content" | grep -q "${test_fsck_1:1}" || return 1
    echo "$initrd_content" | grep -q "${test_fsck_2:1}" || return 1
    echo "$initrd_content" | grep -q "${test_fsck_3:1}" || return 1

    # mix conf file and command line arguments
    cat << EOF > "$TEST_CONF"
install_items+=( "$test_item_1" )
install_optional_items+=( "$test_item_4" )
libdirs+=( "$test_libdir_1" )
fscks+=( $test_fsck_1 )
EOF
    build_with_test_conf --modules fs-lib --no-kernel --install "$test_item_2 $test_item_3" \
        --install-optional "$test_item_5 $test_item_6" \
        --libdirs "$test_libdir_2 $test_libdir_3" \
        --fscks "$test_fsck_2 $test_fsck_3" \
        || return 1
    initrd_content=$("$basedir"/lsinitrd.sh "$TEST_INITRD" | grep -v "Arguments:" | grep "${TEST_ITEMS_DIR:1}")
    echo "$initrd_content" | grep -q "${test_item_1:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_2:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_3:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_4:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_5:1}" || return 1
    echo "$initrd_content" | grep -q "${test_item_6:1}" && return 1
    echo "$initrd_content" | grep -q "${test_libdir_1:1}" && return 1
    echo "$initrd_content" | grep -q "${test_libdir_2:1}" || return 1
    echo "$initrd_content" | grep -q "${test_libdir_3:1}" || return 1
    echo "$initrd_content" | grep -q "${test_fsck_1:1}" || return 1
    echo "$initrd_content" | grep -q "${test_fsck_2:1}" || return 1
    echo "$initrd_content" | grep -q "${test_fsck_3:1}" || return 1

    # fwdirs

    export DRACUT_INSTALL_LOG_LEVEL=7

    test_fwdir_1=$(mktemp -d -p "$TEST_ITEMS_DIR") || return 1
    test_fwdir_2=$(mktemp -d -p "$TEST_ITEMS_DIR") || return 1
    test_fwdir_3=$(mktemp -d -p "$TEST_ITEMS_DIR") || return 1
    test_fwdir_4=$(mktemp -d -p "$TEST_ITEMS_DIR") || return 1
    test_fwdir_5=$(mktemp -d -p "$TEST_ITEMS_DIR") || return 1

    # old style
    cat << EOF > "$TEST_CONF"
fw_dir+=":${test_fwdir_1}:${test_fwdir_2}:${test_fwdir_3}"
EOF
    build_with_test_conf --kernel-only --drivers soundcore \
        | grep -q "DRACUT_FIRMWARE_PATH=:${test_fwdir_1}:${test_fwdir_2}:${test_fwdir_3}" \
        || return 1

    # new style
    cat << EOF > "$TEST_CONF"
fwdirs+=( $test_fwdir_1 $test_fwdir_2 $test_fwdir_3 )
EOF
    build_with_test_conf --kernel-only --drivers soundcore \
        | grep -q "DRACUT_FIRMWARE_PATH=:${test_fwdir_1}:${test_fwdir_2}:${test_fwdir_3}" \
        || return 1

    # mix conf file and command line arguments
    # - old style command line argument: --fwdir
    # - new style command line argument: --fwdirs
    cat << EOF > "$TEST_CONF"
fwdirs+=( $test_fwdir_1 )
EOF
    build_with_test_conf --kernel-only --drivers soundcore \
        --fwdir "$test_fwdir_2 $test_fwdir_3" \
        --fwdirs "$test_fwdir_4 $test_fwdir_5" \
        | grep -q "DRACUT_FIRMWARE_PATH=:${test_fwdir_2}:${test_fwdir_3}:${test_fwdir_4}:${test_fwdir_5}" \
        || return 1

    return 0
}

test_cleanup() {
    [ -d "$TEST_CONF_DIR" ] && rm -rf "$TEST_CONF_DIR"
    [ -d "$TEST_ITEMS_DIR" ] && rm -rf "$TEST_ITEMS_DIR"
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
