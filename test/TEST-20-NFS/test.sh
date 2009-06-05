#!/bin/bash
TEST_DESCRIPTION="root filesystem on NFS"

KVERSION=${KVERSION-$(uname -r)}
BASENET=${BASENET-192.168.100}

test_run() {
    # Start server first
    $testdir/run-qemu -hda server.ext2 -m 512M -nographic \
	-net nic,macaddr=52:54:00:12:34:56,model=e1000 \
	-net socket,mcast=230.0.0.1:1234 \
	-serial udp:127.0.0.1:9999 \
	-kernel /boot/vmlinuz-$KVERSION \
	-append "root=/dev/sda rw quiet console=ttyS0,115200n81" \
	-initrd initramfs.server -pidfile server.pid -daemonize
    sudo chmod 644 server.pid

    # Starting the server messes up the terminal, fix that
    stty sane

    echo Sleeping 10 seconds to give the server a head start
    sleep 10

    $testdir/run-qemu -hda client.img -m 512M -nographic \
	-net nic,macaddr=52:54:00:12:35:56,model=e1000 \
	-net socket,mcast=230.0.0.1:1234 \
	-kernel /boot/vmlinuz-$KVERSION \
	-append "root=dhcp rw quiet console=ttyS0,115200n81" \
	-initrd initramfs.testing

    if [[ -s server.pid ]]; then
	sudo kill -TERM $(cat server.pid)
	rm -f server.pid
    fi
    grep -m 1 -q nfs-OK client.img || return 1
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
	    rpcbind modprobe rpc.nfsd rpc.mountd dnsmasq showmount tcpdump \
	    /etc/netconfig /etc/services sleep
	instmods nfsd sunrpc
	inst ./server-init /sbin/init
	(
	    cd "$initdir";
	    mkdir -p dev sys proc etc var/run tmp var/lib/{dnsmasq,rpcbind,nfs}
	    mkdir -p var/lib/nfs/v4recovery
	    chmod 777 var/lib/rpcbind var/lib/nfs

	    cat > etc/hosts <<EOF 
127.0.0.1                localhost
$BASENET.1          server
$BASENET.100        workstation1
$BASENET.101        workstation2
$BASENET.102        workstation3
$BASENET.103        workstation4
EOF
	    cat > etc/dnsmasq.conf <<EOF
expand-hosts
domain=test.net
dhcp-range=$BASENET.100,$BASENET.150,168h
dhcp-option=17,"$BASENET.1:/client"
EOF
	    cat > etc/basenet <<EOF
BASENET=$BASENET
EOF

            cat > etc/exports <<EOF
/	$BASENET.0/24(ro,fsid=0,insecure,no_subtree_check,no_root_squash)
/client	$BASENET.0/24(ro,insecure,no_subtree_check,no_root_squash)
EOF
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
	-m "dash udev-rules base rootfs-block" \
	-d "ata_piix ext2 sd_mod e1000" \
	-f initramfs.server $KVERSION || return 1

    # Make client's dracut image
    $basedir/dracut -l -i overlay / \
	-m "dash udev-rules base network nfs" \
	-d "e1000 nfs sunrpc" \
	-f initramfs.testing $KVERSION || return 1

    # Need this so kvm-qemu will boot (needs non-/dev/zero local disk)
    dd if=/dev/zero of=client.img bs=1M count=1
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
