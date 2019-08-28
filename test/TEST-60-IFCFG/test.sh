#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
TEST_DESCRIPTION="root filesystem on NFS with bridging/bonding/vlan"
KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"
#DEBUGFAIL="rd.shell rd.break rd.debug"
#SERIAL="tcp:127.0.0.1:9999"

run_server() {
    # Start server first
    echo "MULTINIC TEST SETUP: Starting DHCP/NFS server"

    fsck -a "$TESTDIR"/server.ext3 || return 1

    $testdir/run-qemu \
        -hda "$TESTDIR"/server.ext3 \
        -m 512M -smp 2 \
        -display none \
        -netdev socket,id=n0,listen=127.0.0.1:12370 \
        -netdev socket,id=n1,listen=127.0.0.1:12371 \
        -netdev socket,id=n2,listen=127.0.0.1:12372 \
        -netdev socket,id=n3,listen=127.0.0.1:12373 \
        -device e1000,netdev=n0,mac=52:54:01:12:34:56 \
        -device e1000,netdev=n1,mac=52:54:01:12:34:57 \
        -device e1000,netdev=n2,mac=52:54:01:12:34:58 \
        -device e1000,netdev=n3,mac=52:54:01:12:34:59 \
        ${SERIAL:+-serial "$SERIAL"} \
        ${SERIAL:--serial file:"$TESTDIR"/server.log} \
        -watchdog i6300esb -watchdog-action poweroff \
        -no-reboot \
        -append "panic=1 loglevel=7 root=/dev/sda rootfstype=ext3 rw console=ttyS0,115200n81 selinux=0 rd.debug" \
        -initrd "$TESTDIR"/initramfs.server \
        -pidfile "$TESTDIR"/server.pid -daemonize || return 1
    chmod 644 -- "$TESTDIR"/server.pid || return 1

    # Cleanup the terminal if we have one
    tty -s && stty sane

    echo Sleeping 10 seconds to give the server a head start
    sleep 10
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
        nic1=" -netdev socket,connect=127.0.0.1:12371,id=n1"
        nic3=" -netdev socket,connect=127.0.0.1:12373,id=n3"
    else
        nic1=" -netdev hubport,id=n1,hubid=2"
        nic3=" -netdev hubport,id=n3,hubid=3"
    fi

    if $testdir/run-qemu --help | grep -qF -m1 'netdev hubport,id=str,hubid=n[,netdev=nd]' && echo OK; then
        $testdir/run-qemu \
            -hda "$TESTDIR"/client.img -m 512M -smp 2 -nographic \
            -netdev socket,connect=127.0.0.1:12370,id=s1 \
            -netdev hubport,hubid=1,id=h1,netdev=s1 \
            -netdev hubport,hubid=1,id=h2 -device e1000,mac=52:54:00:12:34:01,netdev=h2 \
            -netdev hubport,hubid=1,id=h3 -device e1000,mac=52:54:00:12:34:02,netdev=h3 \
            $nic1 -device e1000,mac=52:54:00:12:34:03,netdev=n1  \
            -netdev socket,connect=127.0.0.1:12372,id=n2 -device e1000,mac=52:54:00:12:34:04,netdev=n2 \
            $nic3 -device e1000,mac=52:54:00:12:34:05,netdev=n3 \
            -watchdog i6300esb -watchdog-action poweroff \
            -no-reboot \
            -append "panic=1 $cmdline rd.debug $DEBUGFAIL rd.retry=5 rw console=ttyS0,115200n81 selinux=0 init=/sbin/init" \
            -initrd "$TESTDIR"/initramfs.testing
    else
        $testdir/run-qemu \
            -hda "$TESTDIR"/client.img -m 512M -smp 2 -nographic \
            -net socket,vlan=0,connect=127.0.0.1:12370 \
            ${do_vlan13:+-net socket,vlan=1,connect=127.0.0.1:12371} \
            -net socket,vlan=2,connect=127.0.0.1:12372 \
            ${do_vlan13:+-net socket,vlan=3,connect=127.0.0.1:12373} \
            -net nic,vlan=0,macaddr=52:54:00:12:34:01,model=e1000 \
            -net nic,vlan=0,macaddr=52:54:00:12:34:02,model=e1000 \
            -net nic,vlan=1,macaddr=52:54:00:12:34:03,model=e1000 \
            -net nic,vlan=2,macaddr=52:54:00:12:34:04,model=e1000 \
            -net nic,vlan=3,macaddr=52:54:00:12:34:05,model=e1000 \
            -watchdog i6300esb -watchdog-action poweroff \
            -no-reboot \
            -append "panic=1 $cmdline rd.debug $DEBUGFAIL rd.retry=5 rw console=ttyS0,115200n81 selinux=0 init=/sbin/init" \
            -initrd "$TESTDIR"/initramfs.testing
    fi

    { 
        read OK
        if [[ "$OK" != "OK" ]]; then
            echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
            return 1
        fi

        while read line; do
            [[ $line == END ]] && break
            CONF+="$line "
        done
    } < "$TESTDIR"/client.img || return 1

    if [[ "$check" != "$CONF" ]]; then
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
    test_client || { kill_server; return 1; }
}

test_client() {
    client_test "Multiple VLAN" \
        "yes" \
        "
vlan=vlan0001:ens5
vlan=vlan2:ens5
vlan=ens5.3:ens5
vlan=ens5.0004:ens5
ip=ens3:dhcp
ip=192.168.54.101::192.168.54.1:24:test:vlan0001:none
ip=192.168.55.102::192.168.55.1:24:test:vlan2:none
ip=192.168.56.103::192.168.56.1:24:test:ens5.3:none
ip=192.168.57.104::192.168.57.1:24:test:ens5.0004:none
rd.neednet=1
root=nfs:192.168.50.1:/nfs/client bootdev=ens3
" \
    'ens3 ens5.0004 ens5.3 vlan0001 vlan2 /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-ens3 # Generated by dracut initrd NAME="ens3" DEVICE="ens3" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp TYPE=Ethernet /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-ens5.0004 # Generated by dracut initrd NAME="ens5.0004" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.57.104" PREFIX="24" GATEWAY="192.168.57.1" TYPE=Vlan DEVICE="ens5.0004" VLAN=yes PHYSDEV="ens5" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-ens5.3 # Generated by dracut initrd NAME="ens5.3" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.56.103" PREFIX="24" GATEWAY="192.168.56.1" TYPE=Vlan DEVICE="ens5.3" VLAN=yes PHYSDEV="ens5" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-vlan0001 # Generated by dracut initrd NAME="vlan0001" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.54.101" PREFIX="24" GATEWAY="192.168.54.1" TYPE=Vlan DEVICE="vlan0001" VLAN=yes PHYSDEV="ens5" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-vlan2 # Generated by dracut initrd NAME="vlan2" ONBOOT=yes NETBOOT=yes BOOTPROTO=none IPADDR="192.168.55.102" PREFIX="24" GATEWAY="192.168.55.1" TYPE=Vlan DEVICE="vlan2" VLAN=yes PHYSDEV="ens5" EOF ' \
    || return 1

    client_test "Multiple Bonds" \
        "yes" \
        "
bond=bond0:ens4,ens5
bond=bond1:ens6,ens7
ip=bond0:dhcp
ip=bond1:dhcp
rd.neednet=1
root=nfs:192.168.50.1:/nfs/client bootdev=bond0
" \
    'bond0 bond1 /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-bond0 # Generated by dracut initrd NAME="bond0" DEVICE="bond0" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp BONDING_OPTS="" NAME="bond0" TYPE=Bond /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-bond1 # Generated by dracut initrd NAME="bond1" DEVICE="bond1" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp BONDING_OPTS="" NAME="bond1" TYPE=Bond /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-ens4 # Generated by dracut initrd NAME="ens4" TYPE=Ethernet ONBOOT=yes NETBOOT=yes SLAVE=yes MASTER="bond0" DEVICE="ens4" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-ens5 # Generated by dracut initrd NAME="ens5" TYPE=Ethernet ONBOOT=yes NETBOOT=yes SLAVE=yes MASTER="bond0" DEVICE="ens5" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-ens6 # Generated by dracut initrd NAME="ens6" TYPE=Ethernet ONBOOT=yes NETBOOT=yes SLAVE=yes MASTER="bond1" DEVICE="ens6" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-ens7 # Generated by dracut initrd NAME="ens7" TYPE=Ethernet ONBOOT=yes NETBOOT=yes SLAVE=yes MASTER="bond1" DEVICE="ens7" EOF ' \
    || return 1

    client_test "Multiple Bridges" \
        "no" \
        "
bridge=br0:ens4,ens5
bridge=br1:ens6,ens7
ip=br0:dhcp
ip=br1:dhcp
rd.neednet=1
root=nfs:192.168.50.1:/nfs/client bootdev=br0
" \
    'br0 br1 /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-br0 # Generated by dracut initrd NAME="br0" DEVICE="br0" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp TYPE=Bridge NAME="br0" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-br1 # Generated by dracut initrd NAME="br1" DEVICE="br1" ONBOOT=yes NETBOOT=yes IPV6INIT=yes BOOTPROTO=dhcp TYPE=Bridge NAME="br1" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-ens4 # Generated by dracut initrd NAME="ens4" TYPE=Ethernet ONBOOT=yes NETBOOT=yes BRIDGE="br0" DEVICE="ens4" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-ens5 # Generated by dracut initrd NAME="ens5" TYPE=Ethernet ONBOOT=yes NETBOOT=yes BRIDGE="br0" DEVICE="ens5" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-ens6 # Generated by dracut initrd NAME="ens6" TYPE=Ethernet ONBOOT=yes NETBOOT=yes BRIDGE="br1" DEVICE="ens6" /run/initramfs/state/etc/sysconfig/network-scripts/ifcfg-ens7 # Generated by dracut initrd NAME="ens7" TYPE=Ethernet ONBOOT=yes NETBOOT=yes BRIDGE="br1" DEVICE="ens7" EOF ' \
    || return 1

    kill_server
    return 0
}

test_setup() {
     # Make server root
    dd if=/dev/null of="$TESTDIR"/server.ext3 bs=1M seek=120
    mke2fs -j -F -- "$TESTDIR"/server.ext3
    mkdir -- "$TESTDIR"/mnt
    mount -o loop -- "$TESTDIR"/server.ext3 "$TESTDIR"/mnt
    kernel=$KVERSION
    (
        export initdir="$TESTDIR"/mnt
        . "$basedir"/dracut-init.sh

        (
            cd "$initdir";
            mkdir -p -- dev sys proc run etc var/run tmp var/lib/{dhcpd,rpcbind}
            mkdir -p -- var/lib/nfs/{v4recovery,rpc_pipefs}
            chmod 777 -- var/lib/rpcbind var/lib/nfs
        )

        for _f in modules.builtin.bin modules.builtin; do
            [[ $srcmods/$_f ]] && break
        done || {
            dfatal "No modules.builtin.bin and modules.builtin found!"
            return 1
        }

        for _f in modules.builtin.bin modules.builtin modules.order; do
            [[ $srcmods/$_f ]] && inst_simple "$srcmods/$_f" "/lib/modules/$kernel/$_f"
        done

        inst_multiple sh ls shutdown poweroff stty cat ps ln ip \
            dmesg mkdir cp ping exportfs \
            modprobe rpc.nfsd rpc.mountd showmount tcpdump \
            /etc/services sleep mount chmod
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f "${_terminfodir}"/l/linux ] && break
        done
        inst_multiple -o "${_terminfodir}"/l/linux
        type -P portmap >/dev/null && inst_multiple portmap
        type -P rpcbind >/dev/null && inst_multiple rpcbind
        [ -f /etc/netconfig ] && inst_multiple /etc/netconfig
        type -P dhcpd >/dev/null && inst_multiple dhcpd
        [ -x /usr/sbin/dhcpd3 ] && inst /usr/sbin/dhcpd3 /usr/sbin/dhcpd
        instmods nfsd sunrpc ipv6 lockd af_packet 8021q ipvlan macvlan
        inst_simple /etc/os-release
        inst ./server-init.sh /sbin/init
        inst ./hosts /etc/hosts
        inst ./exports /etc/exports
        inst ./dhcpd.conf /etc/dhcpd.conf
        inst_multiple /etc/nsswitch.conf /etc/rpc /etc/protocols

        inst_multiple rpc.idmapd /etc/idmapd.conf

        inst_libdir_file 'libnfsidmap_nsswitch.so*'
        inst_libdir_file 'libnfsidmap/*.so*'
        inst_libdir_file 'libnfsidmap*.so*'

        _nsslibs=$(sed -e '/^#/d' -e 's/^.*://' -e 's/\[NOTFOUND=return\]//' /etc/nsswitch.conf \
            |  tr -s '[:space:]' '\n' | sort -u | tr -s '[:space:]' '|')
        _nsslibs=${_nsslibs#|}
        _nsslibs=${_nsslibs%|}

        inst_libdir_file -n "$_nsslibs" 'libnss_*.so*'

        inst /etc/nsswitch.conf /etc/nsswitch.conf
        inst /etc/passwd /etc/passwd
        inst /etc/group /etc/group

        cp -a -- /etc/ld.so.conf* "$initdir"/etc
        ldconfig -r "$initdir"
        dracut_kernel_post
    )

    # Make client root inside server root
    (
        export initdir="$TESTDIR"/mnt/nfs/client
        . "$basedir"/dracut-init.sh
        inst_multiple sh shutdown poweroff stty cat ps ln ip \
            mount dmesg mkdir cp ping grep ls sort
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [[ -f ${_terminfodir}/l/linux ]] && break
        done
        inst_multiple -o "${_terminfodir}"/l/linux
        inst_simple /etc/os-release
        inst ./client-init.sh /sbin/init
        (
            cd "$initdir"
            mkdir -p -- dev sys proc etc run
            mkdir -p -- var/lib/nfs/rpc_pipefs
        )
        inst /etc/nsswitch.conf /etc/nsswitch.conf
        inst /etc/passwd /etc/passwd
        inst /etc/group /etc/group

        inst_multiple rpc.idmapd /etc/idmapd.conf
        inst_libdir_file 'libnfsidmap_nsswitch.so*'
        inst_libdir_file 'libnfsidmap/*.so*'
        inst_libdir_file 'libnfsidmap*.so*'

        _nsslibs=$(sed -e '/^#/d' -e 's/^.*://' -e 's/\[NOTFOUND=return\]//' -- /etc/nsswitch.conf \
            |  tr -s '[:space:]' '\n' | sort -u | tr -s '[:space:]' '|')
        _nsslibs=${_nsslibs#|}
        _nsslibs=${_nsslibs%|}

        inst_libdir_file -n "$_nsslibs" 'libnss_*.so*'

        cp -a -- /etc/ld.so.conf* "$initdir"/etc
        ldconfig -r "$initdir"
    )

    umount "$TESTDIR"/mnt
    rm -fr -- "$TESTDIR"/mnt

    # Make an overlay with needed tools for the test harness
    (
        export initdir="$TESTDIR"/overlay
        . "$basedir"/dracut-init.sh
        inst_multiple poweroff shutdown
        inst_hook emergency 000 ./hard-off.sh
        inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    # Make server's dracut image
    $basedir/dracut.sh -l -i "$TESTDIR"/overlay / \
        --no-early-microcode \
        -m "udev-rules base rootfs-block fs-lib debug kernel-modules watchdog" \
        -d "ipvlan macvlan af_packet piix ide-gd_mod ata_piix ext3 sd_mod nfsv2 nfsv3 nfsv4 nfs_acl nfs_layout_nfsv41_files nfsd e1000 i6300esb ib700wdt" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.server "$KVERSION" || return 1

    # Make client's dracut image
    $basedir/dracut.sh -l -i "$TESTDIR"/overlay / \
        --no-early-microcode \
        -o "plymouth" \
        -a "debug network-legacy" \
        -d "ipvlan macvlan af_packet piix sd_mod sr_mod ata_piix ide-gd_mod e1000 nfsv2 nfsv3 nfsv4 nfs_acl nfs_layout_nfsv41_files sunrpc i6300esb ib700wdt" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1
}

kill_server() {
    if [[ -s "$TESTDIR"/server.pid ]]; then
        kill -TERM -- $(cat "$TESTDIR"/server.pid)
        rm -f -- "$TESTDIR"/server.pid
    fi
}

test_cleanup() {
    kill_server
}

. "$testdir"/test-functions
