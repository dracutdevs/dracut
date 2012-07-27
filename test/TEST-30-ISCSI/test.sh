#!/bin/bash
TEST_DESCRIPTION="root filesystem over iSCSI"

KVERSION=${KVERSION-$(uname -r)}

#DEBUGFAIL="rd.shell"
#SERIAL="tcp:127.0.0.1:9999"
SERIAL="null"

run_server() {
    # Start server first
    echo "iSCSI TEST SETUP: Starting DHCP/iSCSI server"

    $testdir/run-qemu \
        -hda $TESTDIR/server.ext3 \
        -hdb $TESTDIR/root.ext3 \
        -hdc $TESTDIR/iscsidisk2.img \
        -hdd $TESTDIR/iscsidisk3.img \
        -m 256M -nographic \
        -serial $SERIAL \
        -net nic,macaddr=52:54:00:12:34:56,model=e1000 \
        -net socket,listen=127.0.0.1:12330 \
        -kernel /boot/vmlinuz-$KVERSION \
        -append "root=/dev/sda rootfstype=ext3 rw rd.debug loglevel=77 console=ttyS0,115200n81 selinux=0" \
        -initrd $TESTDIR/initramfs.server \
        -pidfile $TESTDIR/server.pid -daemonize || return 1
    sudo chmod 644 $TESTDIR/server.pid || return 1

    # Cleanup the terminal if we have one
    tty -s && stty sane

    echo Sleeping 10 seconds to give the server a head start
    sleep 10
}

run_client() {
    local test_name=$1; shift
    echo "CLIENT TEST START: $test_name"

    dd if=/dev/zero of=$TESTDIR/client.img bs=1M count=1

    $testdir/run-qemu \
        -hda $TESTDIR/client.img \
        -m 256M -nographic \
        -net nic,macaddr=52:54:00:12:34:00,model=e1000 \
        -net socket,connect=127.0.0.1:12330 \
        -kernel /boot/vmlinuz-$KVERSION \
        -append "$* rw quiet rd.retry=5 rd.debug rd.info  console=ttyS0,115200n81 selinux=0 $DEBUGFAIL" \
        -initrd $TESTDIR/initramfs.testing
    if ! grep -m 1 -q iscsi-OK $TESTDIR/client.img; then
	echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
	return 1
    fi

    echo "CLIENT TEST END: $test_name [OK]"
    return 0
}

do_test_run() {

    run_client "root=dhcp" \
        "root=dhcp" \
	|| return 1

    run_client "root=iscsi" \
	"root=iscsi:192.168.50.1::::iqn.2009-06.dracut:target0" \
	"ip=192.168.50.101::192.168.50.1:255.255.255.0:iscsi-1:eth0:off" \
	|| return 1

    run_client "netroot=iscsi" \
	"root=LABEL=sysroot ip=192.168.50.101::192.168.50.1:255.255.255.0:iscsi-1:eth0:off" \
	"netroot=iscsi:192.168.50.1::::iqn.2009-06.dracut:target1 netroot=iscsi:192.168.50.1::::iqn.2009-06.dracut:target2" \
	|| return 1
    return 0
}

test_run() {
    if ! run_server; then
        echo "Failed to start server" 1>&2
        return 1
    fi
    do_test_run
    ret=$?
    if [[ -s $TESTDIR/server.pid ]]; then
        sudo kill -TERM $(cat $TESTDIR/server.pid)
        rm -f $TESTDIR/server.pid
    fi
    return $ret
}

test_setup() {
    if [ ! -x /usr/sbin/iscsi-target ]; then
        echo "Need iscsi-target from netbsd-iscsi"
        return 1
    fi

    # Create the blank file to use as a root filesystem
    dd if=/dev/null of=$TESTDIR/root.ext3 bs=1M seek=20
    dd if=/dev/null of=$TESTDIR/iscsidisk2.img bs=1M seek=20
    dd if=/dev/null of=$TESTDIR/iscsidisk3.img bs=1M seek=20

    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
        export initdir=$TESTDIR/overlay/source
        . $basedir/dracut-functions.sh
        dracut_install sh shutdown poweroff stty cat ps ln ip \
            mount dmesg mkdir cp ping grep
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        dracut_install -o ${_terminfodir}/l/linux
        inst ./client-init.sh /sbin/init
        (cd "$initdir"; mkdir -p dev sys proc etc var/run tmp )
        cp -a /etc/ld.so.conf* $initdir/etc
        sudo ldconfig -r "$initdir"
    )

    # second, install the files needed to make the root filesystem
    (
        export initdir=$TESTDIR/overlay
        . $basedir/dracut-functions.sh
        dracut_install sfdisk mkfs.ext3 poweroff cp umount
        inst_hook initqueue 01 ./create-root.sh
        inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    $basedir/dracut.sh -l -i $TESTDIR/overlay / \
        -m "dash crypt lvm mdraid udev-rules base rootfs-block kernel-modules" \
        -d "piix ide-gd_mod ata_piix ext3 sd_mod" \
        -f $TESTDIR/initramfs.makeroot $KVERSION || return 1
    rm -rf $TESTDIR/overlay


    # Need this so kvm-qemu will boot (needs non-/dev/zero local disk)
    if ! dd if=/dev/null of=$TESTDIR/client.img bs=1M seek=1; then
        echo "Unable to make client sdb image" 1>&2
        return 1
    fi
    # Invoke KVM and/or QEMU to actually create the target filesystem.
    $testdir/run-qemu \
        -hda $TESTDIR/root.ext3 \
        -hdb $TESTDIR/client.img \
        -hdc $TESTDIR/iscsidisk2.img \
        -hdd $TESTDIR/iscsidisk3.img \
        -m 256M -nographic -net none \
        -kernel "/boot/vmlinuz-$kernel" \
        -append "root=/dev/dracut/root rw rootfstype=ext3 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd $TESTDIR/initramfs.makeroot  || return 1
    grep -m 1 -q dracut-root-block-created $TESTDIR/client.img || return 1
    rm $TESTDIR/client.img
    (
        export initdir=$TESTDIR/overlay
        . $basedir/dracut-functions.sh
        dracut_install poweroff shutdown
        inst_hook emergency 000 ./hard-off.sh
        inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )
    sudo $basedir/dracut.sh -l -i $TESTDIR/overlay / \
        -o "plymouth dmraid" \
        -a "debug" \
        -d "af_packet piix ide-gd_mod ata_piix ext3 sd_mod" \
        -f $TESTDIR/initramfs.testing $KVERSION || return 1

    # Make server root
    dd if=/dev/null of=$TESTDIR/server.ext3 bs=1M seek=60
    mkfs.ext3 -j -F $TESTDIR/server.ext3
    mkdir $TESTDIR/mnt
    sudo mount -o loop $TESTDIR/server.ext3 $TESTDIR/mnt

    kernel=$KVERSION
    (
        export initdir=$TESTDIR/mnt
        . $basedir/dracut-functions.sh
        (
            cd "$initdir";
            mkdir -p dev sys proc etc var/run tmp var/lib/dhcpd /etc/iscsi
        )
        inst /etc/passwd /etc/passwd
        dracut_install sh ls shutdown poweroff stty cat ps ln ip \
            dmesg mkdir cp ping \
            modprobe tcpdump \
            /etc/services sleep mount chmod
        dracut_install /usr/sbin/iscsi-target
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        dracut_install -o ${_terminfodir}/l/linux
        instmods iscsi_tcp crc32c ipv6
        inst ./targets /etc/iscsi/targets
        [ -f /etc/netconfig ] && dracut_install /etc/netconfig
        type -P dhcpd >/dev/null && dracut_install dhcpd
        [ -x /usr/sbin/dhcpd3 ] && inst /usr/sbin/dhcpd3 /usr/sbin/dhcpd
        inst ./server-init.sh /sbin/init
        inst ./hosts /etc/hosts
        inst ./dhcpd.conf /etc/dhcpd.conf
        dracut_install /etc/nsswitch.conf /etc/rpc /etc/protocols
        inst /etc/group /etc/group

        cp -a /etc/ld.so.conf* $initdir/etc
        sudo ldconfig -r "$initdir"
        dracut_kernel_post
    )

    sudo umount $TESTDIR/mnt
    rm -fr $TESTDIR/mnt

    # Make server's dracut image
    $basedir/dracut.sh -l -i $TESTDIR/overlay / \
        -m "dash udev-rules base rootfs-block debug kernel-modules" \
        -d "af_packet piix ide-gd_mod ata_piix ext3 sd_mod e1000" \
        -f $TESTDIR/initramfs.server $KVERSION || return 1

}

test_cleanup() {
    if [[ -s $TESTDIR/server.pid ]]; then
        sudo kill -TERM $(cat $TESTDIR/server.pid)
        rm -f $TESTDIR/server.pid
    fi
}

. $testdir/test-functions
