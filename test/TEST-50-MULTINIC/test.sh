#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
TEST_DESCRIPTION="root filesystem on NFS with multiple nics"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell"
#SERIAL="tcp:127.0.0.1:9999"
SERIAL="null"

run_server() {
    # Start server first
    echo "MULTINIC TEST SETUP: Starting DHCP/NFS server"

    fsck -a $TESTDIR/server.ext3 || return 1
    $testdir/run-qemu \
        -hda $TESTDIR/server.ext3 \
        -m 512M \
        -nographic \
        -netdev socket,mcast=230.0.0.1:12320,id=net0 \
        -net nic,macaddr=52:54:01:12:34:56,model=e1000,netdev=net0 \
        -serial $SERIAL \
        -watchdog i6300esb -watchdog-action poweroff \
        -kernel /boot/vmlinuz-$KVERSION \
        -append "rd.debug loglevel=77 root=/dev/sda rootfstype=ext3 rw console=ttyS0,115200n81 selinux=0" \
        -initrd $TESTDIR/initramfs.server \
        -pidfile $TESTDIR/server.pid -daemonize || return 1
    sudo chmod 644 $TESTDIR/server.pid || return 1

    # Cleanup the terminal if we have one
    tty -s && stty sane

    echo Sleeping 10 seconds to give the server a head start
    sleep 10
}

client_test() {
    local test_name="$1"
    local mac1="$2"
    local mac2="$3"
    local mac3="$4"
    local cmdline="$5"
    local check="$6"

    echo "CLIENT TEST START: $test_name"

    # Need this so kvm-qemu will boot (needs non-/dev/zero local disk)
    if ! dd if=/dev/zero of=$TESTDIR/client.img bs=1M count=1; then
        echo "Unable to make client sda image" 1>&2
        return 1
    fi

    $testdir/run-qemu -hda $TESTDIR/client.img -m 512M -nographic \
        -netdev socket,mcast=230.0.0.1:12320,id=net0 \
        -net nic,netdev=net0,macaddr=52:54:00:12:34:$mac1,model=e1000 \
        -netdev socket,mcast=230.0.0.1:12320,id=net1 \
        -net nic,netdev=net1,macaddr=52:54:00:12:34:$mac2,model=e1000 \
        -netdev socket,mcast=230.0.0.1:12320,id=net2 \
        -net nic,netdev=net2,macaddr=52:54:00:12:34:$mac3,model=e1000 \
        -watchdog i6300esb -watchdog-action poweroff \
        -kernel /boot/vmlinuz-$KVERSION \
        -append "$cmdline $DEBUGFAIL rd.retry=5 rd.debug rd.info  ro rd.systemd.log_level=debug console=ttyS0,115200n81 selinux=0 rd.copystate rd.chroot init=/sbin/init" \
        -initrd $TESTDIR/initramfs.testing

    if [[ $? -ne 0 ]] || ! grep -m 1 -q OK $TESTDIR/client.img; then
        echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
        return 1
    fi


    for i in $check ; do
        echo $i
        if ! grep -m 1 -q $i $TESTDIR/client.img; then
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
    test_client || { kill_server; return 1; }
}

test_client() {
    # Mac Numbering Scheme
    # ...:00-02 receive IP adresses all others don't
    # ...:02 receives a dhcp root-path

    # PXE Style BOOTIF=
    client_test "MULTINIC root=nfs BOOTIF=" \
        00 01 02 \
        "root=nfs:192.168.50.1:/nfs/client BOOTIF=52-54-00-12-34-00" \
        "eth0" || return 1

    # PXE Style BOOTIF= with dhcp root-path
    client_test "MULTINIC root=dhcp BOOTIF=" \
        00 01 02 \
        "root=dhcp BOOTIF=52-54-00-12-34-02" \
        "eth2" || return 1

    # Multinic case, where only one nic works
    client_test "MULTINIC root=nfs ip=dhcp" \
        FF 00 FE \
        "root=nfs:192.168.50.1:/nfs/client ip=dhcp" \
        "eth1" || return 1

    # Require two interfaces
    client_test "MULTINIC root=nfs ip=eth1:dhcp ip=eth2:dhcp bootdev=eth1" \
        00 01 02 \
        "root=nfs:192.168.50.1:/nfs/client ip=eth1:dhcp ip=eth2:dhcp bootdev=eth1" \
        "eth1 eth2" || return 1

    # Require three interfaces with dhcp root-path
    client_test "MULTINIC root=dhcp ip=eth0:dhcp ip=eth1:dhcp ip=eth2:dhcp bootdev=eth2" \
        00 01 02 \
        "root=dhcp ip=eth0:dhcp ip=eth1:dhcp ip=eth2:dhcp bootdev=eth2" \
        "eth0 eth1 eth2" || return 1

    kill_server
    return 0
}

test_setup() {
     # Make server root
    dd if=/dev/null of=$TESTDIR/server.ext3 bs=1M seek=60
    mke2fs -j -F $TESTDIR/server.ext3
    mkdir $TESTDIR/mnt
    sudo mount -o loop $TESTDIR/server.ext3 $TESTDIR/mnt

    (
        export initdir=$TESTDIR/mnt
        . $basedir/dracut-functions.sh

        (
            cd "$initdir";
            mkdir -p dev sys proc run etc var/run tmp var/lib/{dhcpd,rpcbind}
            mkdir -p var/lib/nfs/{v4recovery,rpc_pipefs}
            chmod 777 var/lib/rpcbind var/lib/nfs
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

        dracut_install sh ls shutdown poweroff stty cat ps ln ip \
            dmesg mkdir cp ping exportfs \
            modprobe rpc.nfsd rpc.mountd showmount tcpdump \
            /etc/services sleep mount chmod
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        dracut_install -o ${_terminfodir}/l/linux
        type -P portmap >/dev/null && dracut_install portmap
        type -P rpcbind >/dev/null && dracut_install rpcbind
        [ -f /etc/netconfig ] && dracut_install /etc/netconfig
        type -P dhcpd >/dev/null && dracut_install dhcpd
        [ -x /usr/sbin/dhcpd3 ] && inst /usr/sbin/dhcpd3 /usr/sbin/dhcpd
        instmods nfsd sunrpc ipv6 lockd af_packet
        inst ./server-init.sh /sbin/init
        inst ./hosts /etc/hosts
        inst ./exports /etc/exports
        inst ./dhcpd.conf /etc/dhcpd.conf
        dracut_install /etc/nsswitch.conf /etc/rpc /etc/protocols

        dracut_install rpc.idmapd /etc/idmapd.conf

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

        cp -a /etc/ld.so.conf* $initdir/etc
        sudo ldconfig -r "$initdir"
        dracut_kernel_post
    )

    # Make client root inside server root
    (
        export initdir=$TESTDIR/mnt/nfs/client
        . $basedir/dracut-functions.sh
        dracut_install sh shutdown poweroff stty cat ps ln ip \
            mount dmesg mkdir cp ping grep ls
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        dracut_install -o ${_terminfodir}/l/linux
        inst ./client-init.sh /sbin/init
        (
            cd "$initdir"
            mkdir -p dev sys proc etc run
            mkdir -p var/lib/nfs/rpc_pipefs
        )
        inst /etc/nsswitch.conf /etc/nsswitch.conf
        inst /etc/passwd /etc/passwd
        inst /etc/group /etc/group

        dracut_install rpc.idmapd /etc/idmapd.conf
        inst_libdir_file 'libnfsidmap_nsswitch.so*'
        inst_libdir_file 'libnfsidmap/*.so*'
        inst_libdir_file 'libnfsidmap*.so*'

        _nsslibs=$(sed -e '/^#/d' -e 's/^.*://' -e 's/\[NOTFOUND=return\]//' /etc/nsswitch.conf \
            |  tr -s '[:space:]' '\n' | sort -u | tr -s '[:space:]' '|')
        _nsslibs=${_nsslibs#|}
        _nsslibs=${_nsslibs%|}

        inst_libdir_file -n "$_nsslibs" 'libnss_*.so*'

        cp -a /etc/ld.so.conf* $initdir/etc
        sudo ldconfig -r "$initdir"
    )

    sudo umount $TESTDIR/mnt
    rm -fr $TESTDIR/mnt

    # Make an overlay with needed tools for the test harness
    (
        export initdir=$TESTDIR/overlay
        . $basedir/dracut-functions.sh
        dracut_install poweroff shutdown
        inst_hook emergency 000 ./hard-off.sh
        inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    # Make server's dracut image
    $basedir/dracut.sh -l -i $TESTDIR/overlay / \
        -m "dash udev-rules base rootfs-block debug kernel-modules watchdog" \
        -d "af_packet piix ide-gd_mod ata_piix ext3 sd_mod nfsv2 nfsv3 nfsv4 nfs_acl nfs_layout_nfsv41_files nfsd e1000 i6300esbwdt" \
        -f $TESTDIR/initramfs.server $KVERSION || return 1

    # Make client's dracut image
    $basedir/dracut.sh -l -i $TESTDIR/overlay / \
        -o "plymouth" \
        -a "debug" \
        -d "af_packet piix sd_mod sr_mod ata_piix ide-gd_mod e1000 nfsv2 nfsv3 nfsv4 nfs_acl nfs_layout_nfsv41_files sunrpc i6300esbwdt" \
        -f $TESTDIR/initramfs.testing $KVERSION || return 1
}

kill_server() {
    if [[ -s $TESTDIR/server.pid ]]; then
        sudo kill -TERM $(cat $TESTDIR/server.pid)
        rm -f $TESTDIR/server.pid
    fi
}

test_cleanup() {
    kill_server
}

. $testdir/test-functions
