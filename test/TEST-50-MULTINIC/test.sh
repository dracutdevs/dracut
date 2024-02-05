#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on NFS with multiple nics with $USE_NETWORK"

# Uncomment this to debug failures
#DEBUGFAIL="loglevel=7 rd.shell rd.break"
#SERIAL="tcp:127.0.0.1:9999"

# skip the test if ifcfg dracut module can not be installed
test_check() {
    test -d /etc/sysconfig/network-scripts
}

run_server() {
    # Start server first
    echo "MULTINIC TEST SETUP: Starting DHCP/NFS server"

    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/server.img root

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -net socket,listen=127.0.0.1:12350 \
        -net nic,macaddr=52:54:01:12:34:56,model=e1000 \
        -serial "${SERIAL:-"file:$TESTDIR/server.log"}" \
        -device i6300esb -watchdog-action poweroff \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=LABEL=dracut rootfstype=ext4 rw console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.server \
        -pidfile "$TESTDIR"/server.pid -daemonize || return 1

    chmod 644 -- "$TESTDIR"/server.pid || return 1

    # Cleanup the terminal if we have one
    tty -s && stty sane

    if ! [[ $SERIAL ]]; then
        while :; do
            grep Serving "$TESTDIR"/server.log && break
            echo "Waiting for the server to startup"
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
    local mac1="$2"
    local mac2="$3"
    local mac3="$4"
    local cmdline="$5"
    local check="$6"

    echo "CLIENT TEST START: $test_name"

    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    cmdline="$cmdline rd.net.timeout.dhcp=30"

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    test_marker_reset
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -net socket,connect=127.0.0.1:12350 \
        -net nic,macaddr=52:54:00:12:34:"$mac1",model=e1000 \
        -net nic,macaddr=52:54:00:12:34:"$mac2",model=e1000 \
        -net nic,macaddr=52:54:00:12:34:"$mac3",model=e1000 \
        -netdev hubport,id=n1,hubid=1 \
        -netdev hubport,id=n2,hubid=2 \
        -device e1000,netdev=n1,mac=52:54:00:12:34:98 \
        -device e1000,netdev=n2,mac=52:54:00:12:34:99 \
        -device i6300esb -watchdog-action poweroff \
        -append "quiet panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot rd.shell=0 $cmdline $DEBUGFAIL rd.retry=5 ro console=ttyS0,115200n81 selinux=0 init=/sbin/init rd.debug systemd.log_target=console" \
        -initrd "$TESTDIR"/initramfs.testing || return 1

    {
        read -r OK
        read -r IFACES
    } < "$TESTDIR"/marker.img

    if [[ $OK != "OK" ]]; then
        echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
        return 1
    fi

    for i in $check; do
        if [[ " $IFACES " != *\ $i\ * ]]; then
            echo "$i not in '$IFACES'"
            echo "CLIENT TEST END: $test_name [FAILED - BAD IF]"
            return 1
        fi
    done

    for i in $IFACES; do
        if [[ " $check " != *\ $i\ * ]]; then
            echo "$i in '$IFACES', but should not be"
            echo "CLIENT TEST END: $test_name [FAILED - BAD IF]"
            return 1
        fi
    done

    echo "CLIENT TEST END: $test_name [OK]"
    return 0
}

test_run() {
    if ! run_server; then
        echo "Failed to start server" 1>&2
        return 1
    fi
    test_client
    ret=$?
    kill_server
    return $ret
}

test_client() {
    # Mac Numbering Scheme
    # ...:00-02 receive IP addresses all others don't
    # ...:02 receives a dhcp root-path

    # PXE Style BOOTIF=
    client_test "MULTINIC root=nfs BOOTIF=" \
        00 01 02 \
        "root=nfs:192.168.50.1:/nfs/client BOOTIF=52-54-00-12-34-00" \
        "enp0s1" || return 1

    client_test "MULTINIC root=nfs BOOTIF= ip=enp0s3:dhcp" \
        00 01 02 \
        "root=nfs:192.168.50.1:/nfs/client BOOTIF=52-54-00-12-34-00 ip=enp0s2:dhcp" \
        "enp0s1 enp0s2" || return 1

    # PXE Style BOOTIF= with dhcp root-path
    client_test "MULTINIC root=dhcp BOOTIF=" \
        00 01 02 \
        "root=dhcp BOOTIF=52-54-00-12-34-02" \
        "enp0s3" || return 1

    # Multinic case, where only one nic works
    client_test "MULTINIC root=nfs ip=dhcp" \
        FF 00 FE \
        "root=nfs:192.168.50.1:/nfs/client ip=dhcp" \
        "enp0s2" || return 1

    # Require two interfaces
    client_test "MULTINIC root=nfs ip=enp0s2:dhcp ip=enp0s3:dhcp bootdev=enp0s2" \
        00 01 02 \
        "root=nfs:192.168.50.1:/nfs/client ip=enp0s2:dhcp ip=enp0s3:dhcp bootdev=enp0s2" \
        "enp0s2 enp0s3" || return 1

    # Require three interfaces with dhcp root-path
    client_test "MULTINIC root=dhcp ip=enp0s1:dhcp ip=enp0s2:dhcp ip=enp0s3:dhcp bootdev=enp0s3" \
        00 01 02 \
        "root=dhcp ip=enp0s1:dhcp ip=enp0s2:dhcp ip=enp0s3:dhcp bootdev=enp0s3" \
        "enp0s1 enp0s2 enp0s3" || return 1

    client_test "MULTINIC bonding" \
        00 01 02 \
        "root=nfs:192.168.50.1:/nfs/client ip=bond0:dhcp  bond=bond0:enp0s1,enp0s2,enp0s3:mode=balance-rr" \
        "bond0" || return 1

    # bridge, where only one interface is actually connected
    client_test "MULTINIC bridging" \
        00 01 02 \
        "root=nfs:192.168.50.1:/nfs/client ip=bridge0:dhcp::52:54:00:12:34:00 bridge=bridge0:enp0s1,enp0s5,enp0s6" \
        "bridge0" || return 1
    return 0
}

test_setup() {
    export kernel=$KVERSION
    export srcmods="/lib/modules/$kernel/"
    rm -rf -- "$TESTDIR"/overlay
    (
        mkdir -p "$TESTDIR"/overlay/source
        # shellcheck disable=SC2030
        export initdir=$TESTDIR/overlay/source
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
        export initdir=$TESTDIR/overlay/source/nfs/client
        # shellcheck disable=SC1090
        . "$PKGLIBDIR"/dracut-init.sh

        (
            cd "$initdir" || exit
            mkdir -p dev sys proc etc run root usr var/lib/nfs/rpc_pipefs
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
        export initdir=$TESTDIR/overlay
        # shellcheck disable=SC1090
        . "$PKGLIBDIR"/dracut-init.sh
        inst_multiple sfdisk mkfs.ext4 poweroff cp umount sync dd
        inst_hook initqueue 01 ./create-root.sh
        inst_hook initqueue/finished 01 ./finished-false.sh
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -m "bash rootfs-block kernel-modules qemu" \
        -d "piix ide-gd_mod ata_piix ext4 sd_mod" \
        --nomdadmconf \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker 1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/server.img root 120

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

        inst_binary awk
        inst_hook pre-pivot 85 "$PKGLIBDIR/modules.d/45ifcfg/write-ifcfg.sh"
    )
    # Make client's dracut image
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -o "ifcfg plymouth" \
        -a "debug watchdog ${USE_NETWORK}" \
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
        -d "af_packet piix ide-gd_mod ata_piix ext4 sd_mod nfsv2 nfsv3 nfsv4 nfs_acl nfs_layout_nfsv41_files nfsd e1000 i6300esb ib700wdt" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.server "$KVERSION" || return 1

}

kill_server() {
    if [[ -s "$TESTDIR"/server.pid ]]; then
        kill -TERM -- "$(cat "$TESTDIR"/server.pid)"
        rm -f -- "$TESTDIR"/server.pid
    fi
}

test_cleanup() {
    kill_server
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
