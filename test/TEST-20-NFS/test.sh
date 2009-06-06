#!/bin/bash
TEST_DESCRIPTION="root filesystem on NFS"

KVERSION=${KVERSION-$(uname -r)}

run_server() {
    # Start server first
    echo "NFS TEST SETUP: Starting DHCP/NFS server"

    $testdir/run-qemu -hda server.ext2 -m 512M -nographic \
	-net nic,macaddr=52:54:00:12:34:56,model=e1000 \
	-net socket,mcast=230.0.0.1:1234 \
	-serial udp:127.0.0.1:9999 \
	-kernel /boot/vmlinuz-$KVERSION \
	-append "root=/dev/sda rw quiet console=ttyS0,115200n81" \
	-initrd initramfs.server -pidfile server.pid -daemonize || return 1
    sudo chmod 644 server.pid || return 1

    echo Sleeping 10 seconds to give the server a head start
    sleep 10
}

client_test() {
    local test_name="$1"
    local mac=$2
    local cmdline="$3"

    echo "CLIENT TEST START: $test_name"

    # Need this so kvm-qemu will boot (needs non-/dev/zero local disk)
    if ! dd if=/dev/zero of=client.img bs=1M count=1; then
	echo "Unable to make client sda image" 1>&2
	return 1
    fi

    $testdir/run-qemu -hda client.img -m 512M -nographic \
	-net nic,macaddr=$mac,model=e1000 \
	-net socket,mcast=230.0.0.1:1234 \
	-kernel /boot/vmlinuz-$KVERSION \
	-append "$cmdline rw quiet console=ttyS0,115200n81" \
	-initrd initramfs.testing

    if [[ $? -eq 0 ]] && grep -m 1 -q nfs-OK client.img; then
	echo "CLIENT TEST END: $test_name [OK]"
	return 0
    else
	echo "CLIENT TEST END: $test_name [FAILED]"
	return 1
    fi
}

test_run() {
    if ! run_server; then
	echo "Failed to start server" 1>&2
	return 1
    fi

    client_test "NFSv3 root=dhcp" 52:54:00:12:34:00 "root=dhcp" || return 1
}

test_setup() {
    # Make server root
    dd if=/dev/zero of=server.ext2 bs=1M count=20
    mke2fs -F server.ext2
    mkdir mnt
    sudo mount -o loop server.ext2 mnt

    kernel=$KVERSION
    (
    	initdir=mnt
	. $basedir/dracut-functions
	dracut_install sh ls shutdown poweroff stty cat ps ln ip \
	    /lib/terminfo/l/linux dmesg mkdir cp ping exportfs \
	    rpcbind modprobe rpc.nfsd rpc.mountd dhcpd showmount tcpdump \
	    /etc/netconfig /etc/services sleep
	instmods nfsd sunrpc
	inst ./server-init /sbin/init
	inst ./hosts /etc/hosts
	inst ./exports /etc/exports
	inst ./dhcpd.conf /etc/dhcpd.conf
	(
	    cd "$initdir";
	    mkdir -p dev sys proc etc var/run tmp var/lib/{dhcpd,rpcbind,nfs}
	    mkdir -p var/lib/nfs/v4recovery
	    chmod 777 var/lib/rpcbind var/lib/nfs
	)
	inst /etc/nsswitch.conf /etc/nsswitch.conf
	inst /etc/passwd /etc/passwd
	inst /etc/group /etc/group
	for i in /lib*/libnss_files*;do
	    inst_library $i
	done

	/sbin/depmod -a -b "$initdir" $kernel
	ldconfig -n -r "$initdir" /lib* /usr/lib*
    )

    # Make client root inside server root
    initdir=mnt/client
    mkdir $initdir

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
    )

    # Make server's dracut image
    $basedir/dracut -l -i overlay / \
	-m "dash udev-rules base rootfs-block debug" \
	-d "ata_piix ext2 sd_mod e1000" \
	-f initramfs.server $KVERSION || return 1

    # Make client's dracut image
    $basedir/dracut -l -i overlay / \
	-m "dash udev-rules base network nfs debug" \
	-d "e1000 nfs sunrpc" \
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
