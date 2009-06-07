#!/bin/bash
TEST_DESCRIPTION="root filesystem on NFS"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rdinitdebug rdnetdebug"

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

    # Cleanup the terminal if we have one
    tty -s && stty sane

    echo Sleeping 10 seconds to give the server a head start
    sleep 10
}

client_test() {
    local test_name="$1"
    local mac=$2
    local cmdline="$3"
    local server="$4"
    local check_opt="$5"
    local nfsinfo opts found expected

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
	-append "$cmdline $DEBUGFAIL ro quiet console=ttyS0,115200n81" \
	-initrd initramfs.testing

    if [[ $? -ne 0 ]] || ! grep -m 1 -q nfs-OK client.img; then
	echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
	return 1
    fi

    # nfsinfo=( server:/path nfs{,4} options )
    nfsinfo=($(awk '{print $2, $3, $4; exit}' client.img)) 

    if [[ "${nfsinfo[0]%%:*}" != "$server" ]]; then
	echo "CLIENT TEST INFO: got server: ${nfsinfo[0]%%:*}"
	echo "CLIENT TEST INFO: expected server: $server"
	echo "CLIENT TEST END: $test_name [FAILED - WRONG SERVER]"
	return 1
    fi

    found=0
    expected=1
    if [[ ${check_opt:0:1} == '-' ]]; then
	expected=0
	check_opt=${check_opt:1}
    fi
	
    opts=${nfsinfo[2]},
    while [[ $opts ]]; do
	if [[ ${opts%%,*} == $check_opt ]]; then
	    found=1
	    break
	fi
	opts=${opts#*,}
    done

    if [[ $found -ne $expected ]]; then
	echo "CLIENT TEST INFO: got options: ${nfsinfo[2]%%:*}"
	if [[ $expected -eq 0 ]]; then
		echo "CLIENT TEST INFO: did not expect: $check_opt"
		echo "CLIENT TEST END: $test_name [FAILED - UNEXPECTED OPTION]"
	else
		echo "CLIENT TEST INFO: missing: $check_opt"
		echo "CLIENT TEST END: $test_name [FAILED - MISSING OPTION]"
	fi
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

    # MAC numbering scheme:
    # NFSv3: last octect starts at 0x00 and works up
    # NFSv4: last octect starts at 0x80 and works up
    
    client_test "NFSv3 root=dhcp DHCP path only" 52:54:00:12:34:00 \
	"root=dhcp" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 root=nfs DHCP path only" 52:54:00:12:34:00 \
	"root=nfs" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 root=/dev/nfs DHCP path only" 52:54:00:12:34:00 \
	"root=/dev/nfs" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP IP:path" 52:54:00:12:34:01 \
	"root=dhcp" 192.168.50.2 -wsize=4096 || return 1

    client_test "NFSv3 root=nfs DHCP IP:path" 52:54:00:12:34:01 \
	"root=nfs" 192.168.50.2 -wsize=4096 || return 1

    client_test "NFSv3 root=/dev/nfs DHCP IP:path" 52:54:00:12:34:01 \
	"root=/dev/nfs" 192.168.50.2 -wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP proto:IP:path" 52:54:00:12:34:02 \
	"root=dhcp" 192.168.50.3 -wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP proto:IP:path:options" 52:54:00:12:34:03 \
	"root=dhcp" 192.168.50.3 wsize=4096 || return 1

    # There is a mandatory 90 second recovery when starting the NFSv4
    # server, so put these later in the list to avoid a pause when doing
    # switch_root

    client_test "NFSv4 root=nfs4 DHCP path only" 52:54:00:12:34:80 \
	"root=nfs4" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv4 root=/dev/nfs4 DHCP path only" 52:54:00:12:34:80 \
	"root=/dev/nfs4" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv4 root=nfs4 DHCP IP:path" 52:54:00:12:34:81 \
	"root=nfs4" 192.168.50.2 -wsize=4096 || return 1

    client_test "NFSv4 root=/dev/nfs4 DHCP IP:path" 52:54:00:12:34:81 \
	"root=/dev/nfs4" 192.168.50.2 -wsize=4096 || return 1

    client_test "NFSv4 root=dhcp DHCP proto:IP:path" 52:54:00:12:34:82 \
	"root=dhcp" 192.168.50.3 -wsize=4096 || return 1

    client_test "NFSv4 root=dhcp DHCP proto:IP:path:options" 52:54:00:12:34:83 \
	"root=dhcp" 192.168.50.3 wsize=4096 || return 1
}

test_setup() {
    # Make server root
    dd if=/dev/zero of=server.ext2 bs=1M count=30
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
	    /etc/netconfig /etc/services sleep mount
	instmods nfsd sunrpc
	inst ./server-init /sbin/init
	inst ./hosts /etc/hosts
	inst ./exports /etc/exports
	inst ./dhcpd.conf /etc/dhcpd.conf
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
