#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

[ -z "$USE_NETWORK" ] && USE_NETWORK="network-legacy"

# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on NFS with bridging/bonding/vlan with $USE_NETWORK"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"
#SERIAL="tcp:127.0.0.1:9999"

# Network topology:
#
#  .---------------------.    .---------------.
#  |      SERVER-VM      |    |   CLIENT-VM   |
#  |                     |    |               |
#  |    (DHCP) net1  <------------>  net1     |
#  |                     |    |               |
#  |           net2  <------------>  net2     |
#  |   vlan 1 <-|        |    |               |
#  |   vlan 2 <-|        |    |               |
#  |   vlan 3 <-|        |    |               |
#  |   vlan 4 <-.        |    |               |
#  |                     |    |               |
#  |         / net3  <------------>  net3     |
#  |  bond0 |            |    |               |
#  |  (DHCP) \ net4  <------------>  net4     |
#  |                     |    |               |
#  |                     |  X----->  net5     |
#  .---------------------.    .---------------.

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
        -hda "$TESTDIR"/server.ext4 \
        -serial "${SERIAL:-"file:$TESTDIR/server.log"}" \
        -device i6300esb -watchdog-action poweroff \
        -append "panic=1 oops=panic softlockup_panic=1 loglevel=7 root=LABEL=dracut rootfstype=ext4 rw console=ttyS0,115200n81 selinux=0 rd.debug" \
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
    local cmdline="$2"
    local check="$3"
    local CONF

    echo "CLIENT TEST START: $test_name"

    # Need this so kvm-qemu will boot (needs non-/dev/zero local disk)
    if ! dd if=/dev/zero of="$TESTDIR"/client.img bs=1M count=1; then
        echo "Unable to make client sda image" 1>&2
        return 1
    fi

    "$testdir"/run-qemu \
        -netdev socket,connect=127.0.0.1:12370,id=n1 -device virtio-net-pci,mac=52:54:00:12:34:01,netdev=n1 \
        -netdev socket,connect=127.0.0.1:12371,id=n2 -device virtio-net-pci,mac=52:54:00:12:34:02,netdev=n2 \
        -netdev socket,connect=127.0.0.1:12372,id=n3 -device virtio-net-pci,mac=52:54:00:12:34:03,netdev=n3 \
        -netdev socket,connect=127.0.0.1:12373,id=n4 -device virtio-net-pci,mac=52:54:00:12:34:04,netdev=n4 \
        -netdev hubport,id=n5,hubid=1 -device virtio-net-pci,mac=52:54:00:12:34:05,netdev=n5 \
        -hda "$TESTDIR"/client.img \
        -device i6300esb -watchdog-action poweroff \
        -append "
        panic=1 oops=panic softlockup_panic=1
        ifname=net1:52:54:00:12:34:01
        ifname=net2:52:54:00:12:34:02
        ifname=net3:52:54:00:12:34:03
        ifname=net4:52:54:00:12:34:04
        ifname=net5:52:54:00:12:34:05
        $cmdline rd.net.timeout.dhcp=30 systemd.crash_reboot
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

    ### TEST 1: VLANs
    if [ "$USE_NETWORK" = network-legacy ]; then
        NETCONF='ifcfg-net1 # Generated by dracut initrd NAME="net1" HWADDR="52:54:00:12:34:01" DEVICE="net1" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp TYPE=Ethernet ifcfg-net2.0004 # Generated by dracut initrd NAME="net2.0004" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.57.104" PREFIX="24" GATEWAY="192.168.57.1" TYPE=Vlan DEVICE="net2.0004" VLAN=yes PHYSDEV="net2" ifcfg-net2.3 # Generated by dracut initrd NAME="net2.3" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.56.103" PREFIX="24" GATEWAY="192.168.56.1" TYPE=Vlan DEVICE="net2.3" VLAN=yes PHYSDEV="net2" ifcfg-vlan0001 # Generated by dracut initrd NAME="vlan0001" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.54.101" PREFIX="24" GATEWAY="192.168.54.1" TYPE=Vlan DEVICE="vlan0001" VLAN=yes PHYSDEV="net2" ifcfg-vlan2 # Generated by dracut initrd NAME="vlan2" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.55.102" PREFIX="24" GATEWAY="192.168.55.1" TYPE=Vlan DEVICE="vlan2" VLAN=yes PHYSDEV="net2" '
    fi

    client_test "VLANs" \
        "
rd.dracut.test.num=1
rd.dracut.test.net-module=$USE_NETWORK
vlan=vlan0001:net2
vlan=vlan2:net2
vlan=net2.3:net2
vlan=net2.0004:net2
ip=net1:dhcp
ip=192.168.54.101::192.168.54.1:24:test:vlan0001:none
ip=192.168.55.102::192.168.55.1:24:test:vlan2:none
ip=192.168.56.103::192.168.56.1:24:test:net2.3:none
ip=192.168.57.104::192.168.57.1:24:test:net2.0004:none
rd.neednet=1
root=nfs:192.168.50.1:/nfs/client
bootdev=net1
" \
        "net1 net2.0004 net2.3 vlan0001 vlan2 PING1=0 PING2=0 PING3=0 PING4=0 PING5=0 ${NETCONF}EOF " \
        || return 1

    ### TEST 2: bond
    if [ "$USE_NETWORK" = network-legacy ]; then
        NETCONF='ifcfg-bond0 # Generated by dracut initrd NAME="bond0" DEVICE="bond0" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp BONDING_OPTS="miimon=100" NAME="bond0" TYPE=Bond ifcfg-net3 # Generated by dracut initrd NAME="net3" TYPE=Ethernet ONBOOT=yes NETBOOT=yes SLAVE=yes MASTER="bond0" DEVICE="net3" ifcfg-net4 # Generated by dracut initrd NAME="net4" TYPE=Ethernet ONBOOT=yes NETBOOT=yes SLAVE=yes MASTER="bond0" DEVICE="net4" '
    fi
    client_test "Bond" \
        "
rd.dracut.test.num=2
rd.dracut.test.net-module=$USE_NETWORK
bond=bond0:net3,net4:miimon=100
ip=bond0:dhcp
rd.neednet=1
root=nfs:192.168.51.1:/nfs/client
bootdev=bond0
" \
        "bond0 PING1=0 NET3=0 NET4=0 ${NETCONF}EOF " \
        || return 1

    ### TEST 3: bridge
    if [ "$USE_NETWORK" = network-legacy ]; then
        NETCONF='ifcfg-br0 # Generated by dracut initrd NAME="br0" DEVICE="br0" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp TYPE=Bridge NAME="br0" ifcfg-net1 # Generated by dracut initrd NAME="net1" TYPE=Ethernet ONBOOT=yes NETBOOT=yes BRIDGE="br0" HWADDR="52:54:00:12:34:01" DEVICE="net1" ifcfg-net5 # Generated by dracut initrd NAME="net5" TYPE=Ethernet ONBOOT=yes NETBOOT=yes BRIDGE="br0" HWADDR="52:54:00:12:34:05" DEVICE="net5" '
    fi
    client_test "Bridge" \
        "
rd.dracut.test.num=3
rd.dracut.test.net-module=$USE_NETWORK
bridge=br0:net1,net5
ip=br0:dhcp
rd.neednet=1
root=nfs:192.168.50.1:/nfs/client
bootdev=br0
" \
        "br0 PING1=0 NET1=0 NET5=0 ${NETCONF}EOF " \
        || return 1

    kill_server
    return 0
}

test_setup() {
    # Make server root
    dd if=/dev/zero of="$TESTDIR"/server.ext4 bs=1M count=120

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
        instmods nfsd sunrpc ipv6 lockd af_packet 8021q bonding
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
            mount dmesg mkdir cp ping grep ls sort dd sed basename
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
        inst_multiple sfdisk mkfs.ext4 poweroff cp umount sync dd
        inst_hook initqueue 01 ./create-root.sh
        inst_hook initqueue/finished 01 ./finished-false.sh
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -m "bash rootfs-block kernel-modules qemu" \
        -d "piix ide-gd_mod ata_piix ext4 sd_mod" \
        --nomdadmconf \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        -drive format=raw,index=0,media=disk,file="$TESTDIR"/server.ext4 \
        -append "root=/dev/dracut/root rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/server.ext4 || return 1
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
        -a "debug ${USE_NETWORK}" \
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
    # Make server's dracut image
    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        --no-early-microcode \
        -m "rootfs-block debug kernel-modules watchdog qemu network network-legacy" \
        -d "ipvlan macvlan af_packet piix ide-gd_mod ata_piix ext4 sd_mod nfsv2 nfsv3 nfsv4 nfs_acl nfs_layout_nfsv41_files nfsd virtio-net i6300esb ib700wdt" \
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
