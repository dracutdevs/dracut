#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="Full systemd serialization/deserialization test with /usr mount"

test_check() {
    command -v systemctl &> /dev/null
}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"
#DEBUGOUT="quiet systemd.log_level=debug systemd.log_target=console loglevel=77  rd.info rd.debug"
DEBUGOUT="loglevel=0 "
client_run() {
    local test_name="$1"
    shift
    local client_opts="$*"

    echo "CLIENT TEST START: $test_name"

    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.btrfs root
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/usr.btrfs usr

    test_marker_reset
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "systemd.unit=testsuite.target systemd.mask=systemd-firstboot panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=LABEL=dracut $client_opts rd.retry=3 console=ttyS0,115200n81 selinux=0 $DEBUGOUT rd.shell=0 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing || return 1

    if ! test_marker_check; then
        echo "CLIENT TEST END: $test_name [FAILED]"
        return 1
    fi
    echo "CLIENT TEST END: $test_name [OK]"

}

test_run() {
    client_run "no option specified" || return 1
    client_run "readonly root" "ro" || return 1
    client_run "writeable root" "rw" || return 1
    return 0
}

test_setup() {
    # shellcheck disable=SC2064
    trap "$(shopt -p globstar)" RETURN
    shopt -q -s globstar

    # Create what will eventually be our root filesystem onto an overlay
    "$DRACUT" -l --keep --tmpdir "$TESTDIR" \
        -m "test-root systemd" \
        -I "ldconfig" \
        -i ./test-init.sh /sbin/test-init \
        -i ./fstab /etc/fstab \
        -i "${PKGLIBDIR}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh" \
        -i "${PKGLIBDIR}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh" \
        --no-hostonly --no-hostonly-cmdline --nomdadmconf --nohardlink \
        -f "$TESTDIR"/initramfs.root "$KVERSION" || return 1

    mkdir -p "$TESTDIR"/overlay/source && cp -a "$TESTDIR"/dracut.*/initramfs/* "$TESTDIR"/overlay/source && rm -rf "$TESTDIR"/dracut.* && export initdir=$TESTDIR/overlay/source

    if type -P rpm &> /dev/null; then
        rpm -ql systemd | xargs -r "$PKGLIBDIR"/dracut-install ${initdir:+-D "$initdir"} -o -a -l
    elif type -P dpkg &> /dev/null; then
        dpkg -L systemd | xargs -r "$PKGLIBDIR"/dracut-install ${initdir:+-D "$initdir"} -o -a -l
    elif type -P pacman &> /dev/null; then
        pacman -Q -l systemd | while read -r _ a; do printf -- "%s\0" "$a"; done | xargs -0 -r "$PKGLIBDIR"/dracut-install ${initdir:+-D "$initdir"} -o -a -l
    else
        echo "Can't install systemd base"
        return 1
    fi

    # softlink mtab
    ln -fs /proc/self/mounts "$initdir"/etc/mtab

    # install any Execs from the service files
    grep -Eho '^Exec[^ ]*=[^ ]+' "$initdir"{,/usr}/lib/systemd/system/*.service \
        | while read -r i || [ -n "$i" ]; do
            i=${i##Exec*=}
            i=${i##-}
            "$PKGLIBDIR"/dracut-install ${initdir:+-D "$initdir"} -o -a -l "$i"
        done

    # setup the testsuite target
    mkdir -p "$initdir"/etc/systemd/system
    cat > "$initdir"/etc/systemd/system/testsuite.target << EOF
[Unit]
Description=Testsuite target
Requires=basic.target
After=basic.target
Conflicts=rescue.target
AllowIsolate=yes
EOF

    # setup the testsuite service
    cat > "$initdir"/etc/systemd/system/testsuite.service << EOF
[Unit]
Description=Testsuite service
After=basic.target

[Service]
ExecStart=/sbin/test-init
Type=oneshot
StandardInput=tty
StandardOutput=tty
EOF

    mkdir -p "$initdir"/etc/systemd/system/testsuite.target.wants
    ln -fs ../testsuite.service "$initdir"/etc/systemd/system/testsuite.target.wants/testsuite.service

    # second, install the files needed to make the root filesystem
    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -m "test-makeroot bash btrfs" \
        -I "mkfs.btrfs" \
        -i ./create-root.sh /lib/dracut/hooks/initqueue/01-create-root.sh \
        --nomdadmconf \
        --nohardlink \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay/*

    # Create the blank file to use as a root filesystem
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker 1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.btrfs root 160
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/usr.btrfs usr 160

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/fakeroot rw rootfstype=btrfs quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1

    if ! test_marker_check dracut-root-block-created; then
        echo "Could not create root filesystem"
        return 1
    fi

    [ -e /etc/machine-id ] && EXTRA_MACHINE="/etc/machine-id"
    [ -e /etc/machine-info ] && EXTRA_MACHINE+=" /etc/machine-info"

    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -a "test systemd i18n qemu" \
        ${EXTRA_MACHINE:+-I "$EXTRA_MACHINE"} \
        -o "network plymouth lvm mdraid resume crypt caps dm terminfo usrmount kernel-network-modules rngd" \
        -d "piix ide-gd_mod ata_piix btrfs sd_mod i6300esb ib700wdt" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1

    rm -rf -- "$TESTDIR"/overlay
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
