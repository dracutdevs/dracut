#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on NFS with $USE_NETWORK"

# Uncomment this to debug failures
#DEBUGFAIL="rd.debug loglevel=7 rd.break=initqueue rd.shell"
SERVER_DEBUG="rd.debug loglevel=7"
#SERIAL="unix:/tmp/server.sock"

run_server() {
    # Start server first
    echo "NFS TEST SETUP: Starting DHCP/NFS server"
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/server.img root 0 1

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -net socket,listen=127.0.0.1:12320 \
        -net nic,macaddr=52:54:00:12:34:56,model=e1000 \
        -serial "${SERIAL:-"file:$TESTDIR/server.log"}" \
        -device i6300esb -watchdog-action poweroff \
        -append "panic=1 oops=panic softlockup_panic=1 root=LABEL=dracut rootfstype=ext4 rw console=ttyS0,115200n81 selinux=0 $SERVER_DEBUG" \
        -initrd "$TESTDIR"/initramfs.server \
        -pidfile "$TESTDIR"/server.pid -daemonize || return 1
    chmod 644 "$TESTDIR"/server.pid || return 1

    # Cleanup the terminal if we have one
    tty -s && stty sane

    if ! [[ $SERIAL ]]; then
        while ! grep -q Serving "$TESTDIR"/server.log; do
            echo "Waiting for the server to startup"
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
    local server="$4"
    local check_opt="$5"
    local nfsinfo opts found expected

    echo "CLIENT TEST START: $test_name"

    # Need this so kvm-qemu will boot (needs non-/dev/zero local disk)
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker 1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker2.img marker2 1
    cmdline="$cmdline rd.net.timeout.dhcp=30"

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -net nic,macaddr="$mac",model=e1000 \
        -net socket,connect=127.0.0.1:12320 \
        -device i6300esb -watchdog-action poweroff \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot rd.shell=0 $cmdline $DEBUGFAIL rd.retry=10 quiet ro console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.testing

    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]] || ! test_marker_check nfs-OK; then
        echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
        return 1
    fi

    # nfsinfo=( server:/path nfs{,4} options )
    read -r -a nfsinfo < <(awk '{print $2, $3, $4; exit}' "$TESTDIR"/marker.img)

    if [[ ${nfsinfo[0]%%:*} != "$server" ]]; then
        echo "CLIENT TEST INFO: got server: ${nfsinfo[0]%%:*}"
        echo "CLIENT TEST INFO: expected server: $server"
        echo "CLIENT TEST END: $test_name [FAILED - WRONG SERVER]"
        return 1
    fi

    found=0
    expected=1
    if [[ ${check_opt:0:1} == '-' ]]; then
        expected=0
        check_opt=${check_opt:1}
    fi

    opts=${nfsinfo[2]},
    while [[ $opts ]]; do
        if [[ ${opts%%,*} == "$check_opt" ]]; then
            found=1
            break
        fi
        opts=${opts#*,}
    done

    if [[ $found -ne $expected ]]; then
        echo "CLIENT TEST INFO: got options: ${nfsinfo[2]%%:*}"
        if [[ $expected -eq 0 ]]; then
            echo "CLIENT TEST INFO: did not expect: $check_opt"
            echo "CLIENT TEST END: $test_name [FAILED - UNEXPECTED OPTION]"
        else
            echo "CLIENT TEST INFO: missing: $check_opt"
            echo "CLIENT TEST END: $test_name [FAILED - MISSING OPTION]"
        fi
        return 1
    fi

    if ! test_marker_check nfsfetch-OK marker2.img; then
        echo "CLIENT TEST END: $test_name [FAILED - NFS FETCH FAILED]"
        return 1
    fi

    echo "CLIENT TEST END: $test_name [OK]"
    return 0
}

test_nfsv3() {
    # MAC numbering scheme:
    # NFSv3: last octet starts at 0x00 and works up
    # NFSv4: last octet starts at 0x80 and works up

    client_test "NFSv3 root=dhcp DHCP path only" 52:54:00:12:34:00 \
        "root=dhcp" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 Legacy root=/dev/nfs nfsroot=IP:path" 52:54:00:12:34:01 \
        "root=/dev/nfs nfsroot=192.168.50.1:/nfs/client" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 Legacy root=/dev/nfs DHCP path only" 52:54:00:12:34:00 \
        "root=/dev/nfs" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 Legacy root=/dev/nfs DHCP IP:path" 52:54:00:12:34:01 \
        "root=/dev/nfs" 192.168.50.2 -wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP IP:path" 52:54:00:12:34:01 \
        "root=dhcp" 192.168.50.2 -wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP proto:IP:path" 52:54:00:12:34:02 \
        "root=dhcp" 192.168.50.3 -wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP proto:IP:path:options" 52:54:00:12:34:03 \
        "root=dhcp" 192.168.50.3 wsize=4096 || return 1

    client_test "NFSv3 root=nfs:..." 52:54:00:12:34:04 \
        "root=nfs:192.168.50.1:/nfs/client" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 Bridge root=nfs:..." 52:54:00:12:34:04 \
        "root=nfs:192.168.50.1:/nfs/client bridge net.ifnames=0" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 Legacy root=IP:path" 52:54:00:12:34:04 \
        "root=192.168.50.1:/nfs/client" 192.168.50.1 -wsize=4096 || return 1

    # This test must fail: nfsroot= requires root=/dev/nfs
    client_test "NFSv3 Invalid root=dhcp nfsroot=/nfs/client" 52:54:00:12:34:04 \
        "root=dhcp nfsroot=/nfs/client failme" 192.168.50.1 -wsize=4096 && return 1

    client_test "NFSv3 root=dhcp DHCP path,options" 52:54:00:12:34:05 \
        "root=dhcp" 192.168.50.1 wsize=4096 || return 1

    client_test "NFSv3 Bridge Customized root=dhcp DHCP path,options" 52:54:00:12:34:05 \
        "root=dhcp bridge=foobr0:enp0s1" 192.168.50.1 wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP IP:path,options" 52:54:00:12:34:06 \
        "root=dhcp" 192.168.50.2 wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP proto:IP:path,options" 52:54:00:12:34:07 \
        "root=dhcp" 192.168.50.3 wsize=4096 || return 1

    client_test "NFSv3 Overlayfs root=nfs:..." 52:54:00:12:34:04 \
        "root=nfs:192.168.50.1:/nfs/client rd.live.overlay.overlayfs=1" \
        192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 Live Overlayfs root=nfs:..." 52:54:00:12:34:04 \
        "root=nfs:192.168.50.1:/nfs/client rd.live.image rd.live.overlay.overlayfs=1" \
        192.168.50.1 -wsize=4096 || return 1

    return 0
}

test_nfsv4() {
    # There is a mandatory 90 second recovery when starting the NFSv4
    # server, so put these later in the list to avoid a pause when doing
    # switch_root

    client_test "NFSv4 root=dhcp DHCP proto:IP:path" 52:54:00:12:34:82 \
        "root=dhcp" 192.168.50.3 -wsize=4096 || return 1

    client_test "NFSv4 root=dhcp DHCP proto:IP:path:options" 52:54:00:12:34:83 \
        "root=dhcp" 192.168.50.3 wsize=4096 || return 1

    client_test "NFSv4 root=nfs4:..." 52:54:00:12:34:84 \
        "root=nfs4:192.168.50.1:/client" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv4 root=dhcp DHCP proto:IP:path,options" 52:54:00:12:34:87 \
        "root=dhcp" 192.168.50.3 wsize=4096 || return 1

    return 0
}

test_run() {
    if [[ -s server.pid ]]; then
        kill -TERM "$(cat "$TESTDIR"/server.pid)"
        rm -f -- "$TESTDIR"/server.pid
    fi

    if ! run_server; then
        echo "Failed to start server" 1>&2
        return 1
    fi

    test_nfsv3 \
        && test_nfsv4

    ret=$?

    if [[ -s $TESTDIR/server.pid ]]; then
        kill -TERM "$(cat "$TESTDIR"/server.pid)"
        rm -f -- "$TESTDIR"/server.pid
    fi

    return $ret
}

test_setup() {
    export kernel=$KVERSION
    export srcmods="/lib/modules/$kernel/"
    # Detect lib paths

    rm -rf -- "$TESTDIR"/overlay
    (
        mkdir -p "$TESTDIR"/server/overlay/source
        # shellcheck disable=SC2030
        export initdir=$TESTDIR/server/overlay/source
        # shellcheck disable=SC1090
        . "$PKGLIBDIR"/dracut-init.sh

        (
            cd "$initdir" || exit
            mkdir -p dev sys proc run etc var/run tmp var/lib/{dhcpd,rpcbind}
            mkdir -p var/lib/nfs/{v4recovery,rpc_pipefs}
            chmod 777 var/lib/rpcbind var/lib/nfs
        )

        inst_multiple sh ls shutdown poweroff stty cat ps ln ip \
            dmesg mkdir cp ping exportfs \
            modprobe rpc.nfsd rpc.mountd showmount tcpdump \
            sleep mount chmod rm
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            if [ -f "${_terminfodir}"/l/linux ]; then
                inst_multiple -o "${_terminfodir}"/l/linux
                break
            fi
        done
        type -P portmap > /dev/null && inst_multiple portmap
        type -P rpcbind > /dev/null && inst_multiple rpcbind

        [ -f /etc/netconfig ] && inst_multiple /etc/netconfig
        type -P dhcpd > /dev/null && inst_multiple dhcpd
        instmods nfsd sunrpc ipv6 lockd af_packet
        inst ./server-init.sh /sbin/init
        inst_simple /etc/os-release
        inst ./hosts /etc/hosts
        inst ./exports /etc/exports
        inst ./dhcpd.conf /etc/dhcpd.conf
        inst_multiple -o {,/usr}/etc/nsswitch.conf {,/usr}/etc/rpc \
            {,/usr}/etc/protocols {,/usr}/etc/services
        inst_multiple -o rpc.idmapd /etc/idmapd.conf

        inst_libdir_file 'libnfsidmap_nsswitch.so*'
        inst_libdir_file 'libnfsidmap/*.so*'
        inst_libdir_file 'libnfsidmap*.so*'

        _nsslibs=$(
            cat "$dracutsysrootdir"/{,usr/}etc/nsswitch.conf 2> /dev/null \
                | sed -e '/^#/d' -e 's/^.*://' -e 's/\[NOTFOUND=return\]//' \
                | tr -s '[:space:]' '\n' | sort -u | tr -s '[:space:]' '|'
        )
        _nsslibs=${_nsslibs#|}
        _nsslibs=${_nsslibs%|}
        inst_libdir_file -n "$_nsslibs" 'libnss_*.so*'

        inst /etc/passwd /etc/passwd
        inst /etc/group /etc/group

        cp -a /etc/ld.so.conf* "$initdir"/etc
        ldconfig -r "$initdir"
        dracut_kernel_post
    )

    # Make client root inside server root
    (
        # shellcheck disable=SC2030
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/server/overlay/source/nfs/client
        # shellcheck disable=SC1090
        . "$PKGLIBDIR"/dracut-init.sh

        (
            cd "$initdir" || exit
            mkdir -p dev sys proc etc run root usr var/lib/nfs/rpc_pipefs
            echo "TEST FETCH FILE" > root/fetchfile
        )

        inst_multiple sh shutdown poweroff stty cat ps ln ip dd \
            mount dmesg mkdir cp ping grep setsid ls vi less cat sync
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            if [ -f "${_terminfodir}"/l/linux ]; then
                inst_multiple -o "${_terminfodir}"/l/linux
                break
            fi
        done

        inst_simple "${PKGLIBDIR}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh"
        inst_simple "${PKGLIBDIR}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh"
        inst_simple "${PKGLIBDIR}/modules.d/45url-lib/url-lib.sh" "/lib/url-lib.sh"
        inst_simple "${PKGLIBDIR}/modules.d/45net-lib/net-lib.sh" "/lib/net-lib.sh"
        inst_simple "${PKGLIBDIR}/modules.d/95nfs/nfs-lib.sh" "/lib/nfs-lib.sh"
        inst_binary "${PKGLIBDIR}/dracut-util" "/usr/bin/dracut-util"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getarg"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getargs"

        inst ./client-init.sh /sbin/init
        inst_simple /etc/os-release
        inst_multiple -o {,/usr}/etc/nsswitch.conf
        inst /etc/passwd /etc/passwd
        inst /etc/group /etc/group

        inst_libdir_file 'libnfsidmap_nsswitch.so*'
        inst_libdir_file 'libnfsidmap/*.so*'
        inst_libdir_file 'libnfsidmap*.so*'

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
    )

    # second, install the files needed to make the root filesystem
    (
        # shellcheck disable=SC2030
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/server/overlay
        # shellcheck disable=SC1090
        . "$PKGLIBDIR"/dracut-init.sh
        inst_multiple sfdisk mkfs.ext4 poweroff cp umount sync dd
        inst_hook initqueue 01 ./create-root.sh
        inst_hook initqueue/finished 01 ./finished-false.sh
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$DRACUT" -l -i "$TESTDIR"/server/overlay / \
        -m "bash rootfs-block kernel-modules qemu" \
        -d "piix ide-gd_mod ata_piix ext4 sd_mod" \
        --nomdadmconf \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/server

    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker 1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/server.img root 80

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/dracut/root rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    test_marker_check dracut-root-block-created || return 1

    # Make an overlay with needed tools for the test harness
    (
        # shellcheck disable=SC2031
        # shellcheck disable=SC2030
        export initdir="$TESTDIR"/overlay
        mkdir -p "$TESTDIR"/overlay
        # shellcheck disable=SC1090
        . "$PKGLIBDIR"/dracut-init.sh
        inst_multiple poweroff shutdown
        inst_hook shutdown-emergency 000 ./hard-off.sh
        inst_hook emergency 000 ./hard-off.sh
        inst_simple ./client.link /etc/systemd/network/01-client.link
    )

    # Make client's dracut image
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -o "plymouth" \
        -a "dmsquash-live debug watchdog ${USE_NETWORK}" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1

    (
        # shellcheck disable=SC2031
        export initdir="$TESTDIR"/overlay
        # shellcheck disable=SC1090
        . "$PKGLIBDIR"/dracut-init.sh
        rm "$initdir"/etc/systemd/network/01-client.link
        inst_simple ./server.link /etc/systemd/network/01-server.link
        inst_hook pre-mount 99 ./wait-if-server.sh
    )
    # Make server's dracut image
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -m "bash rootfs-block debug kernel-modules watchdog qemu network network-legacy" \
        -d "af_packet piix ide-gd_mod ata_piix ext4 sd_mod e1000 i6300esb" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.server "$KVERSION" || return 1

    rm -rf -- "$TESTDIR"/overlay
}

test_cleanup() {
    if [[ -s $TESTDIR/server.pid ]]; then
        kill -TERM "$(cat "$TESTDIR"/server.pid)"
        rm -f -- "$TESTDIR"/server.pid
    fi
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
