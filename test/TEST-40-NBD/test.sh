#!/bin/bash
TEST_DESCRIPTION="root filesystem on NBD"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rdinitdebug rdnetdebug"

run_server() {
    # Start server first
    echo "NBD TEST SETUP: Starting DHCP/NBD server"

    $testdir/run-qemu -hda server.ext2 -hdb nbd.ext2 -m 512M -nographic \
	-net nic,macaddr=52:54:00:12:34:56,model=e1000 \
	-net socket,mcast=230.0.0.1:1234 \
	-serial udp:127.0.0.1:9999 \
	-kernel /boot/vmlinuz-$KVERSION \
	-append "root=/dev/sda rw quiet console=ttyS0,115200n81" \
	-initrd initramfs.server -pidfile server.pid -daemonize || return 1
    sudo chmod 644 server.pid || return 1

    # Cleanup the terminal if we have one
    tty -s && stty sane

    echo Sleeping 10 seconds to give the server a head start
    sleep 10
}

client_test() {
    local test_name="$1"
    local mac=$2
    local cmdline="$3"

    echo "CLIENT TEST START: $test_name"

    # Clear out the flags for each test
    if ! dd if=/dev/zero of=flag.img bs=1M count=1; then
	echo "Unable to make client sda image" 1>&2
	return 1
    fi

    $testdir/run-qemu -hda flag.img -m 512M -nographic \
	-net nic,macaddr=$mac,model=e1000 \
	-net socket,mcast=230.0.0.1:1234 \
	-kernel /boot/vmlinuz-$KVERSION \
	-append "$cmdline $DEBUGFAIL ro quiet console=ttyS0,115200n81" \
	-initrd initramfs.testing

    if [[ $? -ne 0 ]] || ! grep -m 1 -q nbd-OK flag.img; then
	echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
	return 1
    fi

    echo "CLIENT TEST END: $test_name [OK]"
}

test_run() {
    if ! run_server; then
	echo "Failed to start server" 1>&2
	return 1
    fi

    client_test "NBD root=nbd:..." 52:54:00:12:34:00 \
	"root=nbd:192.168.50.1:2000" || return 1

    client_test "NBD root=nbd nbdroot=srv:port" 52:54:00:12:34:00 \
	"root=nbd nbdroot=192.168.50.1:2000" || return 1

    client_test "NBD root=dhcp nbdroot=srv:port" 52:54:00:12:34:00 \
	"root=dhcp nbdroot=192.168.50.1:2000" || return 1

    client_test "NBD root=nbd nbdroot=srv,port" 52:54:00:12:34:00 \
	"root=nbd nbdroot=192.168.50.1,2000" || return 1

    client_test "NBD root=dhcp nbdroot=srv,port" 52:54:00:12:34:00 \
	"root=dhcp nbdroot=192.168.50.1,2000" || return 1

    client_test "NBD root=dhcp DHCP root-path nbd:srv:port" 52:54:00:12:34:01 \
	"root=dhcp" || return 1
}

make_client_root() {
    dd if=/dev/zero of=nbd.ext2 bs=1M count=30
    mke2fs -F nbd.ext2
    mkdir mnt
    sudo mount -o loop nbd.ext2 mnt

    kernel=$KVERSION
    (
	initdir=mnt
	. $basedir/dracut-functions
	dracut_install sh ls shutdown poweroff stty cat ps ln ip \
	    /lib/terminfo/l/linux dmesg mkdir cp ping 
	inst ./client-init /sbin/init
	(
	    cd "$initdir";
	    mkdir -p dev sys proc etc var/run tmp
	)
	inst /etc/nsswitch.conf /etc/nsswitch.conf
	inst /etc/passwd /etc/passwd
	inst /etc/group /etc/group
	for i in /lib*/libnss_files**;do
	    inst_library $i
	done

	ldconfig -n -r "$initdir" /lib* /usr/lib*
    )

    sudo umount mnt
    rm -fr mnt
}

make_server_root() {
    dd if=/dev/zero of=server.ext2 bs=1M count=30
    mke2fs -F server.ext2
    mkdir mnt
    sudo mount -o loop server.ext2 mnt

    kernel=$KVERSION
    (
	initdir=mnt
	. $basedir/dracut-functions
	dracut_install sh ls shutdown poweroff stty cat ps ln ip \
	    /lib/terminfo/l/linux dmesg mkdir cp ping grep dhcpd \
	    sleep nbd-server
	inst ./server-init /sbin/init
	inst ./hosts /etc/hosts
	inst ./dhcpd.conf /etc/dhcpd.conf
	(
	    cd "$initdir";
	    mkdir -p dev sys proc etc var/run var/lib/dhcpd tmp
	)
	inst /etc/nsswitch.conf /etc/nsswitch.conf
	inst /etc/passwd /etc/passwd
	inst /etc/group /etc/group
	for i in /lib*/libnss_files**;do
	    inst_library $i
	done

	ldconfig -n -r "$initdir" /lib* /usr/lib*
    )

    sudo umount mnt
    rm -fr mnt
}

test_setup() {
    make_client_root || return 1
    make_server_root || return 1

    # Make the test image
    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install poweroff shutdown
	inst_simple ./hard-off.sh /emergency/01hard-off.sh
    )

    sudo $basedir/dracut -l -i overlay / \
	-m "dash crypt lvm mdraid udev-rules rootfs-block base debug" \
	-d "ata_piix ext2 sd_mod e1000" \
	-f initramfs.server $KVERSION || return 1

    sudo $basedir/dracut -l -i overlay / \
	-m "dash crypt lvm mdraid udev-rules base rootfs-block nbd debug" \
	-d "ata_piix ext2 sd_mod e1000" \
	-f initramfs.testing $KVERSION || return 1
}

test_cleanup() {
    if [[ -s server.pid ]]; then
	sudo kill -TERM $(cat server.pid)
	rm -f server.pid
    fi
    rm -fr overlay mnt
    rm -f flag.img server.ext2 nbd.ext2 initramfs.server initramfs.testing
}

. $testdir/test-functions
