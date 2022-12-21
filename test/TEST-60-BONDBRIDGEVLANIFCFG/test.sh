#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on NFS with bridging/bonding/vlan with $USE_NETWORK"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"
#DEBUGFAIL="rd.shell rd.break rd.debug"
#SERIAL="tcp:127.0.0.1:9999"

run_server() {
    # Start server first
    echo "MULTINIC TEST SETUP: Starting DHCP/NFS server"

    "$testdir"/run-qemu \
        -netdev socket,id=n0,listen=127.0.0.1:12370 \
        -netdev socket,id=n1,listen=127.0.0.1:12371 \
        -netdev socket,id=n2,listen=127.0.0.1:12372 \
        -netdev socket,id=n3,listen=127.0.0.1:12373 \
        -device virtio-net-pci,netdev=n0,mac=52:54:01:12:34:56 \
        -device virtio-net-pci,netdev=n1,mac=52:54:01:12:34:57 \
        -device virtio-net-pci,netdev=n2,mac=52:54:01:12:34:58 \
        -device virtio-net-pci,netdev=n3,mac=52:54:01:12:34:59 \
        -hda "$TESTDIR"/server.ext3 \
        -serial "${SERIAL:-"file:$TESTDIR/server.log"}" \
        -device i6300esb -watchdog-action poweroff \
        -append "panic=1 oops=panic softlockup_panic=1 loglevel=7 root=LABEL=dracut rootfstype=ext3 rw console=ttyS0,115200n81 selinux=0 rd.debug" \
        -initrd "$TESTDIR"/initramfs.server \
        -pidfile "$TESTDIR"/server.pid -daemonize || return 1
    chmod 644 -- "$TESTDIR"/server.pid || return 1

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
    local do_vlan13="$2"
    local cmdline="$3"
    local check="$4"
    local CONF

    echo "CLIENT TEST START: $test_name"

    [ "$do_vlan13" != "yes" ] && unset do_vlan13

    # Need this so kvm-qemu will boot (needs non-/dev/zero local disk)
    if ! dd if=/dev/zero of="$TESTDIR"/client.img bs=1M count=1; then
        echo "Unable to make client sda image" 1>&2
        return 1
    fi
    if [[ $do_vlan13 ]]; then
        nic1=("-netdev" "socket,connect=127.0.0.1:12371,id=n1")
        nic3=("-netdev" "socket,connect=127.0.0.1:12373,id=n3")
    else
        nic1=("-netdev" "hubport,id=n1,hubid=2")
        nic3=("-netdev" "hubport,id=n3,hubid=3")
    fi

    "$testdir"/run-qemu \
        -netdev socket,connect=127.0.0.1:12370,id=s1 \
        -netdev hubport,hubid=1,id=h1,netdev=s1 \
        -netdev hubport,hubid=1,id=h2 -device virtio-net-pci,mac=52:54:00:12:34:01,netdev=h2 \
        -netdev hubport,hubid=1,id=h3 -device virtio-net-pci,mac=52:54:00:12:34:02,netdev=h3 \
        "${nic1[@]}" -device virtio-net-pci,mac=52:54:00:12:34:03,netdev=n1 \
        -netdev socket,connect=127.0.0.1:12372,id=n2 -device virtio-net-pci,mac=52:54:00:12:34:04,netdev=n2 \
        "${nic3[@]}" -device virtio-net-pci,mac=52:54:00:12:34:05,netdev=n3 \
        -hda "$TESTDIR"/client.img \
        -device i6300esb -watchdog-action poweroff \
        -append "
        panic=1 oops=panic softlockup_panic=1
        ifname=net1:52:54:00:12:34:01
        ifname=net2:52:54:00:12:34:02
        ifname=net3:52:54:00:12:34:03
        ifname=net4:52:54:00:12:34:04
        ifname=net5:52:54:00:12:34:05
        $cmdline rd.net.timeout.dhcp=3 systemd.crash_reboot rd.debug
        $DEBUGFAIL rd.retry=5 rw console=ttyS0,115200n81 selinux=0 init=/sbin/init" \
        -initrd "$TESTDIR"/initramfs.testing || return 1

    {
        read -r OK _
        if [[ $OK != "OK" ]]; then
            echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
            return 1
        fi

        while read -r line; do
            [[ $line == END ]] && break
            CONF+="$line "
        done
    } < "$TESTDIR"/client.img || return 1

    if [[ $check != "$CONF" ]]; then
        echo "Expected: '$check'"
        echo
        echo
        echo "Got:      '$CONF'"
        echo "CLIENT TEST END: $test_name [FAILED - BAD CONF]"
        return 1
    fi

    echo "CLIENT TEST END: $test_name [OK]"
    return 0
}

test_run() {
    if ! run_server; then
        echo "Failed to start server" 1>&2
        return 1
    fi
    test_client || {
        kill_server
        return 1
    }
}

test_client() {
    if [[ $NM ]]; then
        EXPECT='net1 net3.0004 net3.3 vlan0001 vlan2 /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-* EOF '
    else
        EXPECT='net1 net3.0004 net3.3 vlan0001 vlan2 /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-net1 # Generated by dracut initrd NAME="net1" HWADDR="52:54:00:12:34:01" DEVICE="net1" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp TYPE=Ethernet /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-net3.0004 # Generated by dracut initrd NAME="net3.0004" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.57.104" PREFIX="24" GATEWAY="192.168.57.1" TYPE=Vlan DEVICE="net3.0004" VLAN=yes PHYSDEV="net3" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-net3.3 # Generated by dracut initrd NAME="net3.3" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.56.103" PREFIX="24" GATEWAY="192.168.56.1" TYPE=Vlan DEVICE="net3.3" VLAN=yes PHYSDEV="net3" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-vlan0001 # Generated by dracut initrd NAME="vlan0001" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.54.101" PREFIX="24" GATEWAY="192.168.54.1" TYPE=Vlan DEVICE="vlan0001" VLAN=yes PHYSDEV="net3" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-vlan2 # Generated by dracut initrd NAME="vlan2" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.55.102" PREFIX="24" GATEWAY="192.168.55.1" TYPE=Vlan DEVICE="vlan2" VLAN=yes PHYSDEV="net3" EOF '
    fi

    client_test "Multiple VLAN" \
        "yes" \
        "
vlan=vlan0001:net3
vlan=vlan2:net3
vlan=net3.3:net3
vlan=net3.0004:net3
ip=net1:dhcp
ip=192.168.54.101::192.168.54.1:24:test:vlan0001:none
ip=192.168.55.102::192.168.55.1:24:test:vlan2:none
ip=192.168.56.103::192.168.56.1:24:test:net3.3:none
ip=192.168.57.104::192.168.57.1:24:test:net3.0004:none
rd.neednet=1
root=nfs:192.168.50.1:/nfs/client bootdev=net1
" \
        "$EXPECT" \
        || return 1

    if [[ $NM ]]; then
        EXPECT='bond0 /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-* EOF '
    else
        EXPECT='bond0 bond1 /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-bond0 # Generated by dracut initrd NAME="bond0" DEVICE="bond0" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp BONDING_OPTS="" NAME="bond0" TYPE=Bond /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-bond1 # Generated by dracut initrd NAME="bond1" DEVICE="bond1" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp BONDING_OPTS="" NAME="bond1" TYPE=Bond /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-net1 # Generated by dracut initrd NAME="net1" HWADDR="52:54:00:12:34:01" TYPE=Ethernet ONBOOT=yes NETBOOT=yes SLAVE=yes MASTER="bond0" DEVICE="net1" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-net2 # Generated by dracut initrd NAME="net2" HWADDR="52:54:00:12:34:02" TYPE=Ethernet ONBOOT=yes NETBOOT=yes SLAVE=yes MASTER="bond0" DEVICE="net2" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-net4 # Generated by dracut initrd NAME="net4" HWADDR="52:54:00:12:34:04" TYPE=Ethernet ONBOOT=yes NETBOOT=yes SLAVE=yes MASTER="bond1" DEVICE="net4" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-net5 # Generated by dracut initrd NAME="net5" TYPE=Ethernet ONBOOT=yes NETBOOT=yes SLAVE=yes MASTER="bond1" DEVICE="net5" EOF '
    fi

    client_test "Multiple Bonds" \
        "yes" \
        "
bond=bond0:net1,net2:miimon=100
bond=bond1:net4,net5:miimon=100
ip=bond0:dhcp
ip=bond1:dhcp
rd.neednet=1
root=nfs:192.168.50.1:/nfs/client bootdev=bond0
" \
        "$EXPECT" \
        || return 1

    if [[ $NM ]]; then
        EXPECT='br0 br1 /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-* EOF '
    else
        EXPECT='br0 br1 /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-br0 # Generated by dracut initrd NAME="br0" DEVICE="br0" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp TYPE=Bridge NAME="br0" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-br1 # Generated by dracut initrd NAME="br1" DEVICE="br1" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp TYPE=Bridge NAME="br1" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-net1 # Generated by dracut initrd NAME="net1" HWADDR="52:54:00:12:34:01" TYPE=Ethernet ONBOOT=yes NETBOOT=yes BRIDGE="br0" DEVICE="net1" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-net2 # Generated by dracut initrd NAME="net2" HWADDR="52:54:00:12:34:02" TYPE=Ethernet ONBOOT=yes NETBOOT=yes BRIDGE="br0" DEVICE="net2" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-net4 # Generated by dracut initrd NAME="net4" TYPE=Ethernet ONBOOT=yes NETBOOT=yes BRIDGE="br1" DEVICE="net4" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-net5 # Generated by dracut initrd NAME="net5" TYPE=Ethernet ONBOOT=yes NETBOOT=yes BRIDGE="br1" DEVICE="net5" EOF '
    fi

    client_test "Multiple Bridges" \
        "no" \
        "
bridge=br0:net1,net2
bridge=br1:net4,net5
ip=br0:dhcp
ip=br1:dhcp
rd.neednet=1
root=nfs:192.168.50.1:/nfs/client bootdev=br0
" \
        "$EXPECT" \
        || return 1

    kill_server
    return 0
}

test_setup() {
    # Make server root
    dd if=/dev/zero of="$TESTDIR"/server.ext3 bs=1M count=120

    kernel=$KVERSION
    rm -rf -- "$TESTDIR"/overlay
    (
        mkdir -p "$TESTDIR"/overlay/source
        # shellcheck disable=SC2030
        export initdir=$TESTDIR/overlay/source
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh

        (
            cd "$initdir" || exit
            mkdir -p -- dev sys proc run etc var/run tmp var/lib/{dhcpd,rpcbind}
            mkdir -p -- var/lib/nfs/{v4recovery,rpc_pipefs}
            chmod 777 -- var/lib/rpcbind var/lib/nfs
        )

        for _f in modules.builtin.bin modules.builtin; do
            [[ -f $srcmods/$_f ]] && break
        done || {
            dfatal "No modules.builtin.bin and modules.builtin found!"
            return 1
        }

        for _f in modules.builtin.bin modules.builtin modules.order; do
            [[ -f $srcmods/$_f ]] && inst_simple "$srcmods/$_f" "/lib/modules/$kernel/$_f"
        done

        inst_multiple sh ls shutdown poweroff stty cat ps ln ip \
            dmesg mkdir cp ping exportfs \
            modprobe rpc.nfsd rpc.mountd showmount tcpdump \
            /etc/services sleep mount chmod
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f "${_terminfodir}"/l/linux ] && break
        done
        inst_multiple -o "${_terminfodir}"/l/linux
        type -P portmap > /dev/null && inst_multiple portmap
        type -P rpcbind > /dev/null && inst_multiple rpcbind
        [ -f /etc/netconfig ] && inst_multiple /etc/netconfig
        type -P dhcpd > /dev/null && inst_multiple dhcpd
        [ -x /usr/sbin/dhcpd3 ] && inst /usr/sbin/dhcpd3 /usr/sbin/dhcpd
        instmods nfsd sunrpc ipv6 lockd af_packet 8021q ipvlan macvlan
        inst_simple /etc/os-release
        inst ./server-init.sh /sbin/init
        inst ./hosts /etc/hosts
        inst ./exports /etc/exports
        inst ./dhcpd.conf /etc/dhcpd.conf
        inst_multiple -o {,/usr}/etc/nsswitch.conf {,/usr}/etc/rpc {,/usr}/etc/protocols

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

        cp -a -- /etc/ld.so.conf* "$initdir"/etc
        ldconfig -r "$initdir"
        dracut_kernel_post
    )

    # Make client root inside server root
    (
        # shellcheck disable=SC2030
        # shellcheck disable=SC2031
        export initdir=$TESTDIR/overlay/source/nfs/client
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        inst_multiple sh shutdown poweroff stty cat ps ln ip \
            mount dmesg mkdir cp ping grep ls sort dd
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [[ -f ${_terminfodir}/l/linux ]] && break
        done
        inst_multiple -o "${_terminfodir}"/l/linux
        inst_simple /etc/os-release
        inst ./client-init.sh /sbin/init
        (
            cd "$initdir" || exit
            mkdir -p -- dev sys proc etc run
            mkdir -p -- var/lib/nfs/rpc_pipefs
        )
        inst_multiple -o {,/usr}/etc/nsswitch.conf {,/usr}/etc/rpc {,/usr}/etc/protocols
        inst /etc/passwd /etc/passwd
        inst /etc/group /etc/group

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

        cp -a -- /etc/ld.so.conf* "$initdir"/etc
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
        inst_hook initqueue 01 ./create-root.sh
        inst_hook initqueue/finished 01 ./finished-false.sh
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -m "bash rootfs-block kernel-modules qemu" \
        -d "piix ide-gd_mod ata_piix ext3 sd_mod" \
        --nomdadmconf \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        -drive format=raw,index=0,media=disk,file="$TESTDIR"/server.ext3 \
        -append "root=/dev/dracut/root rw rootfstype=ext3 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/server.ext3 || return 1
    rm -fr "$TESTDIR"/overlay

    # Make an overlay with needed tools for the test harness
    (
        # shellcheck disable=SC2031
        # shellcheck disable=SC2030
        export initdir="$TESTDIR"/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        inst_multiple poweroff shutdown
        inst_hook emergency 000 ./hard-off.sh
        inst_simple ./client.link /etc/systemd/network/01-client.link
    )
    # Make client's dracut image
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        --no-early-microcode \
        -o "plymouth" \
        -a "debug network ${USE_NETWORK}" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1

    (
        # shellcheck disable=SC2031
        export initdir="$TESTDIR"/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        inst_simple ./server.link /etc/systemd/network/01-server.link
        inst_hook pre-mount 99 ./wait-if-server.sh
    )
    # Make server's dracut image
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        --no-early-microcode \
        -m "rootfs-block debug kernel-modules watchdog qemu network network-legacy" \
        -d "ipvlan macvlan af_packet piix ide-gd_mod ata_piix ext3 sd_mod nfsv2 nfsv3 nfsv4 nfs_acl nfs_layout_nfsv41_files nfsd virtio-net i6300esb ib700wdt" \
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
