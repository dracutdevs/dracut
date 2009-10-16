#!/bin/bash
TEST_DESCRIPTION="root filesystem on NFS with multiple nics"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rdshell"

run_server() {
    # Start server first
    echo "MULTINIC TEST SETUP: Starting DHCP/NFS server"

    $testdir/run-qemu -hda server.ext2 -m 256M -nographic \
	-net nic,macaddr=52:54:00:12:34:56,model=e1000 \
	-net socket,mcast=230.0.0.1:1234 \
	-serial udp:127.0.0.1:9999 \
	-kernel /boot/vmlinuz-$KVERSION \
	-append "selinux=0 root=/dev/sda rdinitdebug rdinfo rdnetdebug rw quiet console=ttyS0,115200n81" \
	-initrd initramfs.server -pidfile server.pid -daemonize || return 1
    sudo chmod 644 server.pid || return 1

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
    if ! dd if=/dev/zero of=client.img bs=1M count=1; then
	echo "Unable to make client sda image" 1>&2
	return 1
    fi

    $testdir/run-qemu -hda client.img -m 512M -nographic \
  	-net nic,macaddr=52:54:00:12:34:$mac1,model=e1000 \
  	-net nic,macaddr=52:54:00:12:34:$mac2,model=e1000 \
  	-net nic,macaddr=52:54:00:12:34:$mac3,model=e1000 \
  	-net socket,mcast=230.0.0.1:1234 \
  	-kernel /boot/vmlinuz-$KVERSION \
  	-append "$cmdline $DEBUGFAIL rdinitdebug rdinfo rdnetdebug ro quiet console=ttyS0,115200n81 selinux=0 rdshell rdcopystate" \
  	-initrd initramfs.testing

    if [[ $? -ne 0 ]] || ! grep -m 1 -q OK client.img; then
	echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
	return 1
    fi


    for i in $check ; do
	echo $i
	if ! grep -m 1 -q $i client.img; then
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
}

test_setup() {
     # Make server root
     dd if=/dev/zero of=server.ext2 bs=1M count=60
     mke2fs -F server.ext2
     mkdir mnt
     sudo mount -o loop server.ext2 mnt

     kernel=$KVERSION
     (
     	initdir=mnt
 	. $basedir/dracut-functions
 	dracut_install sh ls shutdown poweroff stty cat ps ln ip \
 	    /lib/terminfo/l/linux dmesg mkdir cp ping exportfs \
 	    modprobe rpc.nfsd rpc.mountd showmount tcpdump \
 	    /etc/services sleep mount chmod
 	which portmap >/dev/null 2>&1 && dracut_install portmap
 	which rpcbind >/dev/null 2>&1 && dracut_install rpcbind
 	[ -f /etc/netconfig ] && dracut_install /etc/netconfig 
 	which dhcpd >/dev/null 2>&1 && dracut_install dhcpd
 	[ -x /usr/sbin/dhcpd3 ] && inst /usr/sbin/dhcpd3 /usr/sbin/dhcpd
 	instmods nfsd sunrpc ipv6
 	inst ./server-init /sbin/init
 	inst ./hosts /etc/hosts
 	inst ./exports /etc/exports
 	inst ./dhcpd.conf /etc/dhcpd.conf
 	dracut_install /etc/nsswitch.conf /etc/rpc /etc/protocols
 	dracut_install rpc.idmapd /etc/idmapd.conf
 	if ldd $(which rpc.idmapd) |grep -q lib64; then
 	    LIBDIR="/lib64"
 	else
 	    LIBDIR="/lib"
 	fi

 	dracut_install $(ls {/usr,}$LIBDIR/libnfsidmap*.so* 2>/dev/null )
 	dracut_install $(ls {/usr,}$LIBDIR/libnss*.so 2>/dev/null)
 	(
 	    cd "$initdir";
 	    mkdir -p dev sys proc etc var/run tmp var/lib/{dhcpd,rpcbind}
 	    mkdir -p var/lib/nfs/{v4recovery,rpc_pipefs}
 	    chmod 777 var/lib/rpcbind var/lib/nfs
 	)
 	inst /etc/nsswitch.conf /etc/nsswitch.conf
 	inst /etc/passwd /etc/passwd
 	inst /etc/group /etc/group
 	for i in /lib*/libnss_files**;do
 	    inst_library $i
 	done

 	/sbin/depmod -a -b "$initdir" $kernel
 	ldconfig -n -r "$initdir" /lib* /usr/lib*
     )

    # Make client root inside server root
    initdir=mnt/nfs/client
    mkdir -p $initdir

    (
 	. $basedir/dracut-functions
 	dracut_install sh shutdown poweroff stty cat ps ln ip \
         	/lib/terminfo/l/linux mount dmesg mkdir \
 		cp ping grep
 	inst ./client-init /sbin/init
 	(
 	    cd "$initdir"
 	    mkdir -p dev sys proc etc
 	    mkdir -p var/lib/nfs/rpc_pipefs
	)
 	inst /etc/nsswitch.conf /etc/nsswitch.conf
 	inst /etc/passwd /etc/passwd
 	inst /etc/group /etc/group
 	for i in /lib*/libnss_files*;do
 	    inst_library $i
 	done

 	ldconfig -n -r "$initdir" /lib* /usr/lib*
     )

     sudo umount mnt
     rm -fr mnt

    # Make an overlay with needed tools for the test harness
    (
 	initdir=overlay
 	mkdir overlay
 	. $basedir/dracut-functions
 	dracut_install poweroff shutdown
 	inst_simple ./hard-off.sh /emergency/01hard-off.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    # Make server's dracut image
    $basedir/dracut -l -i overlay / \
	-m "dash udev-rules base rootfs-block debug kernel-modules" \
	-d "piix ide-gd_mod ata_piix ext2 sd_mod e1000" \
	-f initramfs.server $KVERSION || return 1

    # Make client's dracut image
    $basedir/dracut -l -i overlay / \
	-o "plymouth" \
	-a "debug" \
	-d "piix ide-gd_mod e1000 nfs sunrpc" \
	-f initramfs.testing $KVERSION || return 1
}

test_cleanup() {
    if [[ -s server.pid ]]; then
	sudo kill -TERM $(cat server.pid)
	rm -f server.pid
    fi
    rm -rf mnt overlay
    rm -f server.ext2 client.img initramfs.server initramfs.testing
}

. $testdir/test-functions
