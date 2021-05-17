#!/bin/bash

if [[ $NM ]]; then
    USE_NETWORK="network-manager"
    OMIT_NETWORK="network-legacy"
else
    USE_NETWORK="network-legacy"
    OMIT_NETWORK="network-manager"
fi

# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on NBD with $USE_NETWORK"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
# DEBUGFAIL="rd.debug systemd.log_target=console loglevel=7"
#DEBUGFAIL="rd.shell rd.break rd.debug systemd.log_target=console loglevel=7 systemd.log_level=debug"
#SERIAL="tcp:127.0.0.1:9999"

test_check() {
    if ! type -p nbd-server &> /dev/null; then
        echo "Test needs nbd-server... Skipping"
        return 1
    fi

    if ! modinfo -k "$KVERSION" nbd &> /dev/null; then
        echo "Kernel module nbd does not exist"
        return 1
    fi

    return 0
}

run_server() {
    # Start server first
    echo "NBD TEST SETUP: Starting DHCP/NBD server"

    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/unencrypted.img unencrypted
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/encrypted.img encrypted
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/server.img serverroot

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -serial "${SERIAL:-"file:$TESTDIR/server.log"}" \
        -net nic,macaddr=52:54:00:12:34:56,model=e1000 \
        -net socket,listen=127.0.0.1:12340 \
        -append "panic=1 oops=panic softlockup_panic=1 rd.luks=0 systemd.crash_reboot quiet root=/dev/disk/by-id/ata-disk_serverroot rootfstype=ext3 rw console=ttyS0,115200n81 selinux=0 $SERVER_DEBUG" \
        -initrd "$TESTDIR"/initramfs.server \
        -pidfile "$TESTDIR"/server.pid -daemonize || return 1
    chmod 644 "$TESTDIR"/server.pid || return 1

    # Cleanup the terminal if we have one
    tty -s && stty sane

    if ! [[ $SERIAL ]]; then
        echo "Waiting for the server to startup"
        while :; do
            grep Serving "$TESTDIR"/server.log && break
            tail "$TESTDIR"/server.log
            sleep 1
        done
    else
        echo Sleeping 10 seconds to give the server a head start
        sleep 10
    fi
}

client_test() {
    local test_name="$1"
    local mac=$2
    local cmdline="$3"
    local fstype=$4
    local fsopt=$5
    local found opts nbdinfo

    [[ $fstype ]] || fstype=ext3
    [[ $fsopt ]] || fsopt="ro"

    echo "CLIENT TEST START: $test_name"

    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -net nic,macaddr="$mac",model=e1000 \
        -net socket,connect=127.0.0.1:12340 \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot rd.shell=0 $cmdline $DEBUGFAIL rd.auto rd.info rd.retry=10 ro console=ttyS0,115200n81  selinux=0  " \
        -initrd "$TESTDIR"/initramfs.testing

    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]] || ! grep -U --binary-files=binary -F -m 1 -q nbd-OK "$TESTDIR"/marker.img; then
        echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
        return 1
    fi

    # nbdinfo=( fstype fsoptions )
    read -r -a nbdinfo < <(awk '{print $2, $3; exit}' "$TESTDIR"/marker.img)

    if [[ ${nbdinfo[0]} != "$fstype" ]]; then
        echo "CLIENT TEST END: $test_name [FAILED - WRONG FS TYPE] \"${nbdinfo[0]}\" != \"$fstype\""
        return 1
    fi

    opts=${nbdinfo[1]},
    while [[ $opts ]]; do
        if [[ ${opts%%,*} == "$fsopt" ]]; then
            found=1
            break
        fi
        opts=${opts#*,}
    done

    if [[ ! $found ]]; then
        echo "CLIENT TEST END: $test_name [FAILED - BAD FS OPTS] \"${nbdinfo[1]}\" != \"$fsopt\""
        return 1
    fi

    echo "CLIENT TEST END: $test_name [OK]"
}

test_run() {
    if ! run_server; then
        echo "Failed to start server" 1>&2
        return 1
    fi
    client_run
    kill_server
}

client_run() {
    # The default is ext3,errors=continue so use that to determine
    # if our options were parsed and used
    client_test "NBD root=nbd:IP:port" 52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:raw rd.luks=0" || return 1

    client_test "NBD root=nbd:IP:port::fsopts" 52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:raw::errors=panic rd.luks=0" \
        ext3 errors=panic || return 1

    client_test "NBD root=nbd:IP:port:fstype" 52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:raw:ext3 rd.luks=0" ext3 || return 1

    client_test "NBD root=nbd:IP:port:fstype:fsopts" 52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:raw:ext3:errors=panic rd.luks=0" \
        ext3 errors=panic || return 1

    # DHCP root-path parsing

    client_test "NBD root=/dev/root netroot=dhcp DHCP root-path nbd:srv:port" 52:54:00:12:34:01 \
        "root=/dev/root netroot=dhcp ip=dhcp rd.luks=0" || return 1

    client_test "NBD root=/dev/root netroot=dhcp DHCP root-path nbd:srv:port:fstype" \
        52:54:00:12:34:02 "root=/dev/root netroot=dhcp ip=dhcp rd.luks=0" ext2 || return 1

    client_test "NBD root=/dev/root netroot=dhcp DHCP root-path nbd:srv:port::fsopts" \
        52:54:00:12:34:03 "root=/dev/root netroot=dhcp ip=dhcp rd.luks=0" ext3 errors=panic || return 1

    client_test "NBD root=/dev/root netroot=dhcp DHCP root-path nbd:srv:port:fstype:fsopts" \
        52:54:00:12:34:04 "root=/dev/root netroot=dhcp ip=dhcp rd.luks=0" ext2 errors=panic || return 1

    # netroot handling

    client_test "NBD netroot=nbd:IP:port" 52:54:00:12:34:00 \
        "root=LABEL=dracut netroot=nbd:192.168.50.1:raw ip=dhcp rd.luks=0" || return 1

    client_test "NBD root=/dev/root netroot=dhcp DHCP root-path nbd:srv:port:fstype:fsopts" \
        52:54:00:12:34:04 "root=/dev/root netroot=dhcp ip=dhcp rd.luks=0" ext2 errors=panic || return 1

    # Encrypted root handling via LVM/LUKS over NBD

    # shellcheck disable=SC1090
    . "$TESTDIR"/luks.uuid

    client_test "NBD root=LABEL=dracut netroot=nbd:IP:port" \
        52:54:00:12:34:00 \
        "root=LABEL=dracut rd.luks.uuid=$ID_FS_UUID rd.lv.vg=dracut ip=dhcp netroot=nbd:192.168.50.1:encrypted" || return 1

    # XXX This should be ext3,errors=panic but that doesn't currently
    # XXX work when you have a real root= line in addition to netroot=
    # XXX How we should work here needs clarification
    #    client_test "NBD root=LABEL=dracut netroot=dhcp (w/ fstype and opts)" \
    #                52:54:00:12:34:05 \
    #                "root=LABEL=dracut rd.luks.uuid=$ID_FS_UUID rd.lv.vg=dracut netroot=dhcp" || return 1

    if [[ -s server.pid ]]; then
        kill -TERM "$(cat "$TESTDIR"/server.pid)"
        rm -f -- "$TESTDIR"/server.pid
    fi

}

make_encrypted_root() {
    rm -fr "$TESTDIR"/overlay
    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
        # shellcheck disable=SC2030
        export initdir=$TESTDIR/overlay/source
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        mkdir -p "$initdir"
        (
            cd "$initdir" || exit
            mkdir -p dev sys proc etc run var/run tmp
        )

        inst_multiple sh df free ls shutdown poweroff stty cat ps ln ip \
            mount dmesg mkdir cp ping dd sync
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux

        inst_simple "${basedir}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh"
        inst_simple "${basedir}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh"
        inst_binary "${basedir}/dracut-util" "/usr/bin/dracut-util"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getarg"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getargs"

        inst ./client-init.sh /sbin/init
        inst_simple /etc/os-release
        find_binary plymouth > /dev/null && inst_multiple plymouth
        cp -a /etc/ld.so.conf* "$initdir"/etc
        ldconfig -r "$initdir"
    )

    # second, install the files needed to make the root filesystem
    (
        # shellcheck disable=SC2030
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        (
            cd "$initdir" || exit
            mkdir -p dev sys proc etc tmp var run root
            ln -s ../run var/run
        )
        inst_multiple mkfs.ext3 poweroff cp umount dd sync
        inst_hook shutdown-emergency 000 ./hard-off.sh
        inst_hook emergency 000 ./hard-off.sh
        inst_hook initqueue 01 ./create-encrypted-root.sh
        inst_hook initqueue/finished 01 ./finished-false.sh
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -m "dash crypt lvm mdraid udev-rules base rootfs-block fs-lib kernel-modules qemu" \
        -d "piix ide-gd_mod ata_piix ext3 ext3 sd_mod" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    dd if=/dev/zero of="$TESTDIR"/encrypted.img bs=1MiB count=120
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/encrypted.img root

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/fakeroot rw quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/marker.img || return 1
    grep -F -a -m 1 ID_FS_UUID "$TESTDIR"/marker.img > "$TESTDIR"/luks.uuid
}

make_client_root() {
    rm -fr "$TESTDIR"/overlay
    kernel=$KVERSION
    (
        mkdir -p "$TESTDIR"/overlay/source
        # shellcheck disable=SC2030
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay/source
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        mkdir -p "$initdir"
        (
            cd "$initdir" || exit
            mkdir -p dev sys proc etc run var/run tmp
        )
        inst_multiple sh ls shutdown poweroff stty cat ps ln ip \
            dmesg mkdir cp ping dd mount sync
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux

        inst_simple "${basedir}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh"
        inst_simple "${basedir}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh"
        inst_binary "${basedir}/dracut-util" "/usr/bin/dracut-util"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getarg"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getargs"

        inst ./client-init.sh /sbin/init
        inst_simple /etc/os-release
        inst_multiple -o {,/usr}/etc/nsswitch.conf
        inst /etc/passwd /etc/passwd
        inst /etc/group /etc/group
        for i in /usr/lib*/libnss_files* /lib*/libnss_files*; do
            [ -e "$i" ] || continue
            inst "$i"
        done
        cp -a /etc/ld.so.conf* "$initdir"/etc
        ldconfig -r "$initdir"
    )

    # second, install the files needed to make the root filesystem
    (
        # shellcheck disable=SC2030
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        inst_multiple sfdisk mkfs.ext3 poweroff cp umount sync dd
        inst_hook initqueue 01 ./create-client-root.sh
        inst_hook initqueue/finished 01 ./finished-false.sh
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -m "dash udev-rules base rootfs-block fs-lib kernel-modules fs-lib qemu" \
        -d "piix ide-gd_mod ata_piix ext3 sd_mod" \
        --nomdadmconf \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1

    dd if=/dev/zero of="$TESTDIR"/unencrypted.img bs=1MiB count=120
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/unencrypted.img root

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/dracut/root rw rootfstype=ext3 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/marker.img || return 1
    rm -fr "$TESTDIR"/overlay
}

make_server_root() {
    rm -fr "$TESTDIR"/overlay
    # shellcheck disable=SC2031
    export kernel=$KVERSION
    (
        mkdir -p "$TESTDIR"/overlay/source
        # shellcheck disable=SC2030
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay/source
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        mkdir -p "$initdir"
        (
            cd "$initdir" || exit
            mkdir -p run dev sys proc etc var var/lib/dhcpd tmp etc/nbd-server
            ln -s ../run var/run
        )
        cat > "$initdir/etc/nbd-server/config" << EOF
[generic]
[raw]
exportname = /dev/disk/by-id/ata-disk_unencrypted
port = 2000
bs = 4096
[encrypted]
exportname = /dev/disk/by-id/ata-disk_encrypted
port = 2001
bs = 4096
EOF
        inst_multiple sh ls shutdown poweroff stty cat ps ln ip \
            dmesg mkdir cp ping grep \
            sleep nbd-server chmod modprobe vi pidof
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux
        instmods nfsd sunrpc ipv6 lockd af_packet 8021q ipvlan macvlan
        type -P dhcpd > /dev/null && inst_multiple dhcpd
        [ -x /usr/sbin/dhcpd3 ] && inst /usr/sbin/dhcpd3 /usr/sbin/dhcpd
        inst ./server-init.sh /sbin/init
        inst_simple /etc/os-release
        inst ./hosts /etc/hosts
        inst ./dhcpd.conf /etc/dhcpd.conf
        inst_multiple -o {,/usr}/etc/nsswitch.conf
        inst /etc/passwd /etc/passwd
        inst /etc/group /etc/group
        _nsslibs=$(
            cat "$dracutsysrootdir"/{,usr/}etc/nsswitch.conf 2> /dev/null \
                | sed -e '/^#/d' -e 's/^.*://' -e 's/\[NOTFOUND=return\]//' \
                | tr -s '[:space:]' '\n' | sort -u | tr -s '[:space:]' '|'
        )
        _nsslibs=${_nsslibs#|}
        _nsslibs=${_nsslibs%|}

        inst_libdir_file -n "$_nsslibs" 'libnss_*.so*'

        cp -a /etc/ld.so.conf* "$initdir"/etc
        ldconfig -r "$initdir"
        dracut_kernel_post
    )

    # second, install the files needed to make the root filesystem
    (
        # shellcheck disable=SC2030
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        inst_multiple sfdisk mkfs.ext3 poweroff cp umount sync dd sync
        inst_hook initqueue 01 ./create-server-root.sh
        inst_hook initqueue/finished 01 ./finished-false.sh
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -m "dash udev-rules base rootfs-block fs-lib kernel-modules fs-lib qemu" \
        -d "piix ide-gd_mod ata_piix ext3 sd_mod" \
        --nomdadmconf \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1

    dd if=/dev/zero of="$TESTDIR"/server.img bs=1MiB count=120
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/server.img root

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/dracut/root rw rootfstype=ext3 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/marker.img || return 1
    rm -fr "$TESTDIR"/overlay
}

test_setup() {
    make_encrypted_root || return 1
    make_client_root || return 1
    make_server_root || return 1

    rm -fr "$TESTDIR"/overlay
    # Make the test image
    (
        # shellcheck disable=SC2031
        # shellcheck disable=SC2030
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        inst_multiple poweroff shutdown dd
        inst_hook shutdown-emergency 000 ./hard-off.sh
        inst ./cryptroot-ask.sh /sbin/cryptroot-ask

        #        inst ./debug-shell.service /lib/systemd/system/debug-shell.service
        #        mkdir -p "${initdir}/lib/systemd/system/sysinit.target.wants"
        #        ln -fs ../debug-shell.service "${initdir}/lib/systemd/system/sysinit.target.wants/debug-shell.service"

        # shellcheck disable=SC1090
        . "$TESTDIR"/luks.uuid
        mkdir -p "$initdir"/etc
        echo "luks-$ID_FS_UUID /dev/nbd0 /etc/key" > "$initdir"/etc/crypttab
        echo -n test > "$initdir"/etc/key
        inst_simple ./client.link /etc/systemd/network/01-client.link
    )

    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -o "plymouth dash iscsi nfs ${OMIT_NETWORK}" \
        -a "debug watchdog ${USE_NETWORK}" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1

    (
        # shellcheck disable=SC2031
        export initdir="$TESTDIR"/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        rm "$initdir"/etc/systemd/network/01-client.link
        inst_simple ./server.link /etc/systemd/network/01-server.link
        inst_hook pre-mount 99 ./wait-if-server.sh
    )
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -a "udev-rules base rootfs-block fs-lib debug kernel-modules network network-legacy" \
        -d "af_packet piix ide-gd_mod ata_piix ext3 sd_mod e1000 drbg" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.server "$KVERSION" || return 1

    rm -rf -- "$TESTDIR"/overlay
}

kill_server() {
    if [[ -s $TESTDIR/server.pid ]]; then
        kill -TERM "$(cat "$TESTDIR"/server.pid)"
        rm -f -- "$TESTDIR"/server.pid
    fi
}

test_cleanup() {
    kill_server
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
