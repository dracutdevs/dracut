#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="Full systemd serialization/deserialization test with /usr mount"

export KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"
#DEBUGFAIL="rd.shell"
#DEBUGOUT="quiet systemd.log_level=debug systemd.log_target=console loglevel=77  rd.info rd.debug"
DEBUGOUT="loglevel=0 "
client_run() {
    local test_name="$1"
    shift
    local client_opts="$*"

    echo "CLIENT TEST START: $test_name"

    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.btrfs root
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/usr.btrfs usr

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=LABEL=dracut $client_opts rd.retry=3 console=ttyS0,115200n81 selinux=0 $DEBUGOUT rd.shell=0 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing || return 1

    if ! grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success "$TESTDIR"/marker.img; then
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
    trap "$(shopt -p nullglob globstar)" RETURN
    shopt -q -s nullglob globstar

    export kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
        # shellcheck disable=SC2030
        export initdir=$TESTDIR/overlay/source
        mkdir -p "$initdir"
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh

        for d in usr/bin usr/sbin bin etc lib "$libdir" sbin tmp usr var var/log dev proc sys sysroot root run; do
            if [ -L "/$d" ]; then
                inst_symlink "/$d"
            else
                inst_dir "/$d"
            fi
        done

        ln -sfn /run "$initdir/var/run"
        ln -sfn /run/lock "$initdir/var/lock"

        inst_multiple sh df free ls shutdown poweroff stty cat ps ln ip \
            mount dmesg mkdir cp ping dd \
            umount strace less setsid systemctl reset sync

        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux
        inst_multiple grep
        inst_simple ./fstab /etc/fstab
        if type -P rpm &> /dev/null; then
            rpm -ql systemd | xargs -r "$DRACUT_INSTALL" ${initdir:+-D "$initdir"} -o -a -l
        elif type -P pacman &> /dev/null; then
            pacman -Q -l systemd | while read -r _ a; do printf -- "%s\0" "$a"; done | xargs -0 -r "$DRACUT_INSTALL" ${initdir:+-D "$initdir"} -o -a -l
            rm "$initdir"/usr/lib/systemd/system/sysinit.target.wants/systemd-firstboot.service
        else
            echo "Can't install systemd base"
            return 1
        fi
        inst /sbin/init
        inst_multiple -o {,/usr}/lib/systemd/system/"dracut*"

        inst_simple "${basedir}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh"
        inst_binary "${basedir}/dracut-util" "/usr/bin/dracut-util"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getarg"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getargs"

        # make a journal directory
        mkdir -p "$initdir"/var/log/journal

        # install some basic config files
        inst_multiple -o \
            /etc/machine-id \
            /etc/adjtime \
            /etc/passwd \
            /etc/shadow \
            /etc/group \
            /etc/shells \
            {,/usr}/etc/nsswitch.conf \
            /etc/pam.conf \
            /etc/securetty \
            /etc/os-release \
            /etc/localtime

        # we want an empty environment
        : > "$initdir"/etc/environment

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

        inst ./test-init.sh /sbin/test-init

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

        # make the testsuite the default target
        systemctl --root="$initdir" set-default testsuite.target

        # install basic tools needed
        inst_multiple sh bash setsid loadkeys setfont \
            login sulogin gzip sleep echo mount umount
        inst_multiple modprobe

        # install libnss_files for login
        inst_libdir_file "libnss_files*"

        # install dbus and pam
        inst_multiple -o \
            /etc/dbus-1/** \
            /etc/pam.d/** \
            /etc/security/** \
            /lib64/security/** \
            /lib/security/**

        # install dbus socket and service file
        inst_multiple -o \
            /usr/lib/systemd/system/dbus.socket \
            /usr/lib/systemd/system/dbus.service \
            /usr/lib/systemd/system/dbus-broker.service \
            /usr/lib/systemd/system/dbus-daemon.service

        (
            echo "FONT=eurlatgr"
            echo "KEYMAP=us"
        ) > "$initrd"/etc/vconsole.conf

        # install basic keyboard maps and fonts
        for i in \
            /usr/lib/kbd/consolefonts/eurlatgr* \
            /usr/lib/kbd/keymaps/{legacy/,/}include/* \
            /usr/lib/kbd/keymaps/{legacy/,/}i386/include/* \
            /usr/lib/kbd/keymaps/{legacy/,/}i386/qwerty/us.*; do
            [[ -f $i ]] || continue
            inst "$i"
        done

        # some basic terminfo files
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux

        # softlink mtab
        ln -fs /proc/self/mounts "$initdir"/etc/mtab

        # install any Execs from the service files
        grep -Eho '^Exec[^ ]*=[^ ]+' "$initdir"{,/usr}/lib/systemd/system/*.service \
            | while read -r i || [ -n "$i" ]; do
                i=${i##Exec*=}
                i=${i##-}
                inst_multiple -o "$i"
            done

        # some helper tools for debugging
        [[ $DEBUGTOOLS ]] && inst_multiple "$DEBUGTOOLS"

        # install ld.so.conf* and run ldconfig
        cp -a /etc/ld.so.conf* "$initdir"/etc
        ldconfig -r "$initdir"
        ddebug "Strip binaeries"
        find "$initdir" -perm /0111 -type f -print0 | xargs -0 -r strip --strip-unneeded | ddebug

        hostonly='' instmods fuse

        # copy depmod files
        inst /lib/modules/"$kernel"/modules.order
        inst /lib/modules/"$kernel"/modules.builtin
        # generate module dependencies
        if [[ -d $initdir/lib/modules/$kernel ]] \
            && ! depmod -a -b "$initdir" "$kernel"; then
            dfatal "\"depmod -a $kernel\" failed."
            exit 1
        fi
        # disable some services
        systemctl --root "$initdir" mask systemd-update-utmp
        systemctl --root "$initdir" mask systemd-tmpfiles-setup
    )

    # second, install the files needed to make the root filesystem
    (
        # shellcheck disable=SC2030
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        inst_multiple sfdisk mkfs.btrfs btrfs poweroff cp umount sync dd
        inst_hook initqueue 01 ./create-root.sh
        inst_hook initqueue/finished 01 ./finished-false.sh
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -m "bash udev-rules btrfs base rootfs-block fs-lib kernel-modules qemu" \
        -d "piix ide-gd_mod ata_piix btrfs sd_mod" \
        --nomdadmconf \
        --nohardlink \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    # Create the blank file to use as a root filesystem
    dd if=/dev/zero of="$TESTDIR"/root.btrfs bs=1MiB count=160
    dd if=/dev/zero of="$TESTDIR"/usr.btrfs bs=1MiB count=160
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.btrfs root
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/usr.btrfs usr

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/fakeroot rw rootfstype=btrfs quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1

    if ! grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/marker.img; then
        echo "Could not create root filesystem"
        return 1
    fi

    (
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        inst_multiple poweroff shutdown dd
        inst_hook shutdown-emergency 000 ./hard-off.sh
        inst_hook emergency 000 ./hard-off.sh
    )

    [ -e /etc/machine-id ] && EXTRA_MACHINE="/etc/machine-id"
    [ -e /etc/machine-info ] && EXTRA_MACHINE+=" /etc/machine-info"

    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -a "debug systemd i18n qemu" \
        ${EXTRA_MACHINE:+-I "$EXTRA_MACHINE"} \
        -o "dash network plymouth lvm mdraid resume crypt caps dm terminfo usrmount kernel-network-modules rngd" \
        -d "piix ide-gd_mod ata_piix btrfs sd_mod i6300esb ib700wdt" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1

    rm -rf -- "$TESTDIR"/overlay
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
