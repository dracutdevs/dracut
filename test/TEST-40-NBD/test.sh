#!/bin/bash
TEST_DESCRIPTION="root filesystem on NBD"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rdinitdebug rdnetdebug rdbreak"

run_server() {
    # Start server first
    echo "NBD TEST SETUP: Starting DHCP/NBD server"

    $testdir/run-qemu -hda server.ext2 -hdb nbd.ext2 -hdc encrypted.ext2 \
	-m 512M -nographic \
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
    local fstype=$4
    local fsopt=$5
    local found opts nbdinfo

    [[ $fstype ]] || fstype=ext3
    [[ $fsopt ]] || fsopt="errors=continue"

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

    # nbdinfo=( fstype fsoptions )
    nbdinfo=($(awk '{print $2, $3; exit}' flag.img))

    if [[ "${nbdinfo[0]}" != "$fstype" ]]; then
	echo "CLIENT TEST END: $test_name [FAILED - WRONG FS TYPE]"
	return 1
    fi

    opts=${nbdinfo[1]},
    while [[ $opts ]]; do
	if [[ ${opts%%,*} = $fsopt ]]; then
	    found=1
	    break
	fi
	opts=${opts#*,}
    done

    if [[ ! $found ]]; then
	echo "CLIENT TEST END: $test_name [FAILED - BAD FS OPTS]"
	return 1
    fi

    echo "CLIENT TEST END: $test_name [OK]"
}

test_run() {
    if ! run_server; then
	echo "Failed to start server" 1>&2
	return 1
    fi

    # The default is ext3,errors=continue so use that to determine
    # if our options were parsed and used

     client_test "NBD root=nbd:IP:port" 52:54:00:12:34:00 \
 	"root=nbd:192.168.50.1:2000" || return 1

     client_test "NBD root=nbd:IP:port:fstype" 52:54:00:12:34:00 \
 	"root=nbd:192.168.50.1:2000:ext2" ext2 || return 1

     client_test "NBD root=nbd:IP:port::fsopts" 52:54:00:12:34:00 \
 	"root=nbd:192.168.50.1:2000::errors=panic" \
 	ext3 errors=panic || return 1

     client_test "NBD root=nbd:IP:port:fstype:fsopts" 52:54:00:12:34:00 \
 	"root=nbd:192.168.50.1:2000:ext2:errors=panic" \
 	ext2 errors=panic || return 1

     # There doesn't seem to be a good way to validate the NBD options, so
     # just check that we don't screw up the other options

     client_test "NBD root=nbd:IP:port:::NBD opts" 52:54:00:12:34:00 \
 	"root=nbd:192.168.50.1:2000:::bs=2048" || return 1

     client_test "NBD root=nbd:IP:port:fstype::NBD opts" 52:54:00:12:34:00 \
 	"root=nbd:192.168.50.1:2000:ext2::bs=2048" ext2 || return 1

     client_test "NBD root=nbd:IP:port:fstype:fsopts:NBD opts" \
 	52:54:00:12:34:00 \
 	"root=nbd:192.168.50.1:2000:ext2:errors=panic:bs=2048" \
 	ext2 errors=panic || return 1

     # Check legacy parsing

     client_test "NBD root=nbd nbdroot=srv:port" 52:54:00:12:34:00 \
 	"root=nbd nbdroot=192.168.50.1:2000" || return 1

     # This test must fail: root=dhcp ignores nbdroot
     client_test "NBD root=dhcp nbdroot=srv:port" 52:54:00:12:34:00 \
	"root=dhcp nbdroot=192.168.50.1:2000" && return 1

     client_test "NBD root=nbd nbdroot=srv,port" 52:54:00:12:34:00 \
	 "root=nbd nbdroot=192.168.50.1,2000" || return 1

     # This test must fail: root=dhcp ignores nbdroot
     client_test "NBD root=dhcp nbdroot=srv,port" 52:54:00:12:34:00 \
	"root=dhcp nbdroot=192.168.50.1,2000" && return 1

    # DHCP root-path parsing

    client_test "NBD root=dhcp DHCP root-path nbd:srv:port" 52:54:00:12:34:01 \
	"root=dhcp" || return 1

    client_test "NBD root=dhcp DHCP root-path nbd:srv:port:fstype" \
	52:54:00:12:34:02 "root=dhcp" ext2 || return 1

    client_test "NBD root=dhcp DHCP root-path nbd:srv:port::fsopts" \
	52:54:00:12:34:03 "root=dhcp" ext3 errors=panic || return 1

    client_test "NBD root=dhcp DHCP root-path nbd:srv:port:fstype:fsopts" \
	52:54:00:12:34:04 "root=dhcp" ext2 errors=panic || return 1

    # netroot handling

    client_test "NBD netroot=nbd:IP:port" 52:54:00:12:34:00 \
	"netroot=nbd:192.168.50.1:2000" || return 1

    client_test "NBD netroot=dhcp DHCP root-path nbd:srv:port:fstype:fsopts" \
	52:54:00:12:34:04 "netroot=dhcp" ext2 errors=panic || return 1

    # Encrypted root handling via LVM/LUKS over NBD

    client_test "NBD root=/dev/dracut/root netroot=nbd:IP:port" \
	52:54:00:12:34:00 \
	"root=/dev/dracut/root netroot=nbd:192.168.50.1:2001" || return 1

    # XXX This should be ext2,errors=panic but that doesn't currently
    # XXX work when you have a real root= line in addition to netroot=
    # XXX How we should work here needs clarification
    client_test "NBD root=/dev/dracut/root netroot=dhcp (w/ fstype and opts)" \
	52:54:00:12:34:05 \
	"root=/dev/dracut/root netroot=dhcp" || return 1

    if [[ -s server.pid ]]; then
	sudo kill -TERM $(cat server.pid)
	rm -f server.pid
    fi

}

make_encrypted_root() {
    # Create the blank file to use as a root filesystem
    dd if=/dev/zero of=encrypted.ext2 bs=1M count=20
    dd if=/dev/zero of=flag.img bs=1M count=1

    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
	initdir=overlay/source
	. $basedir/dracut-functions
	dracut_install sh df free ls shutdown poweroff stty cat ps ln ip \
	    /lib/terminfo/l/linux mount dmesg mkdir cp ping
	inst ./client-init /sbin/init
	find_binary plymouth >/dev/null && dracut_install plymouth
	(cd "$initdir"; mkdir -p dev sys proc etc var/run tmp )
    )

    # second, install the files needed to make the root filesystem
    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install mke2fs poweroff cp umount
	inst_simple ./create-root.sh /pre-mount/01create-root.sh
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    $basedir/dracut -l -i overlay / \
	-m "dash crypt lvm mdraid udev-rules base rootfs-block" \
	-d "ata_piix ext2 sd_mod" \
	-f initramfs.makeroot $KVERSION || return 1
    rm -rf overlay

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    $testdir/run-qemu -hda flag.img -hdb encrypted.ext2 -m 512M \
	-nographic -net none \
	-kernel "/boot/vmlinuz-$kernel" \
	-append "root=/dev/dracut/root rw quiet console=ttyS0,115200n81" \
	-initrd initramfs.makeroot  || return 1
    grep -m 1 -q dracut-root-block-created flag.img || return 1
}

make_client_root() {
    dd if=/dev/zero of=nbd.ext2 bs=1M count=30
    mke2fs -F -j nbd.ext2
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
	    /lib/terminfo/l/linux dmesg mkdir cp ping grep \
	    sleep nbd-server chmod
	which dhcpd >/dev/null 2>&1 && dracut_install dhcpd
	[ -x /usr/sbin/dhcpd3 ] && inst /usr/sbin/dhcpd3 /usr/sbin/dhcpd
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
    make_encrypted_root || return 1
    make_client_root || return 1
    make_server_root || return 1

    # Make the test image
    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install poweroff shutdown
	inst_simple ./hard-off.sh /emergency/01hard-off.sh
	inst ./cryptroot-ask /sbin/cryptroot-ask
    )

    sudo $basedir/dracut -l -i overlay / \
	-m "dash udev-rules rootfs-block base debug" \
	-d "ata_piix ext2 sd_mod e1000" \
	-f initramfs.server $KVERSION || return 1

    sudo $basedir/dracut -l -i overlay / \
	-m "dash crypt lvm mdraid udev-rules base rootfs-block nbd debug" \
	-d "ata_piix ext2 ext3 sd_mod e1000" \
	-f initramfs.testing $KVERSION || return 1
}

test_cleanup() {
    if [[ -s server.pid ]]; then
	sudo kill -TERM $(cat server.pid)
	rm -f server.pid
    fi
    rm -fr overlay mnt
    rm -f flag.img server.ext2 nbd.ext2 encrypted.ext2
    rm -f initramfs.server initramfs.testing initramfs.makeroot
}

. $testdir/test-functions
