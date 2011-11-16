#!/bin/bash
TEST_DESCRIPTION="root filesystem on LVM PV on a isw dmraid"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"
#DEBUGFAIL="$DEBUGFAIL udev.log-priority=debug"

client_run() {
    echo "CLIENT TEST START: $@"
    $testdir/run-qemu \
	-hda $TESTDIR/root.ext2 \
	-hdb $TESTDIR/disk1 \
	-hdc $TESTDIR/disk2 \
	-m 256M -nographic \
	-net none -kernel /boot/vmlinuz-$KVERSION \
	-append "$@ root=LABEL=root rw quiet rd.retry=5 rd.debug console=ttyS0,115200n81 selinux=0 rd.info $DEBUGFAIL" \
	-initrd $TESTDIR/initramfs.testing
    if ! grep -m 1 -q dracut-root-block-success $TESTDIR/root.ext2; then
	echo "CLIENT TEST END: $@ [FAIL]"
	return 1;
    fi

    sed -i -e 's#dracut-root-block-success#dracut-root-block-xxxxxxx#' $TESTDIR/root.ext2
    echo "CLIENT TEST END: $@ [OK]"
    return 0
}

test_run() {
    echo "IMSM test does not work anymore"
    return 1

    client_run rd.md.imsm || return 1
    client_run || return 1
    client_run rd.dm=0 || return 1
    # This test succeeds, because the mirror parts are found without
    # assembling the mirror itsself, which is what we want
    client_run rd.md=0 rd.md.imsm failme && return 1
    client_run rd.md=0 failme && return 1
    # the following test hangs on newer md
    #client_run rd.dm=0 rd.md.imsm rd.md.conf=0 || return 1
   return 0
}

test_setup() {
    echo "IMSM test does not work anymore"
    return 1

    # Create the blank file to use as a root filesystem
    rm -f $TESTDIR/root.ext2
    rm -f $TESTDIR/disk1
    rm -f $TESTDIR/disk2
    dd if=/dev/null of=$TESTDIR/root.ext2 bs=1M seek=1
    dd if=/dev/null of=$TESTDIR/disk1 bs=1M seek=80
    dd if=/dev/null of=$TESTDIR/disk2 bs=1M seek=80

    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
	initdir=$TESTDIR/overlay/source
	. $basedir/dracut-functions
	dracut_install sh df free ls shutdown poweroff stty cat ps ln ip route \
	    /lib/terminfo/l/linux mount dmesg ifconfig dhclient mkdir cp ping dhclient
	inst "$basedir/modules.d/40network/dhclient-script" "/sbin/dhclient-script"
	inst "$basedir/modules.d/40network/ifup" "/sbin/ifup"
	dracut_install grep
	inst ./test-init /sbin/init
	find_binary plymouth >/dev/null && dracut_install plymouth
	(cd "$initdir"; mkdir -p dev sys proc etc var/run tmp )
	cp -a /etc/ld.so.conf* $initdir/etc
	mkdir $initdir/run
	sudo ldconfig -r "$initdir"
    )

    # second, install the files needed to make the root filesystem
    (
	initdir=$TESTDIR/overlay
	. $basedir/dracut-functions
	dracut_install sfdisk mke2fs poweroff cp umount
	inst_hook initqueue 01 ./create-root.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    $basedir/dracut -l -i $TESTDIR/overlay / \
	-m "dash lvm mdraid dmraid udev-rules base rootfs-block kernel-modules" \
	-d "piix ide-gd_mod ata_piix ext2 sd_mod dm-multipath dm-crypt dm-round-robin faulty linear multipath raid0 raid10 raid1 raid456" \
	-f $TESTDIR/initramfs.makeroot $KVERSION || return 1
    rm -rf $TESTDIR/overlay
    # Invoke KVM and/or QEMU to actually create the target filesystem.
    $testdir/run-qemu \
	-hda $TESTDIR/root.ext2 \
	-hdb $TESTDIR/disk1 \
	-hdc $TESTDIR/disk2 \
	-m 256M -nographic -net none \
	-kernel "/boot/vmlinuz-$kernel" \
	-append "root=/dev/dracut/root rw rootfstype=ext2 quiet console=ttyS0,115200n81 selinux=0" \
	-initrd $TESTDIR/initramfs.makeroot  || return 1
    grep -m 1 -q dracut-root-block-created $TESTDIR/root.ext2 || return 1
    (
	initdir=$TESTDIR/overlay
	. $basedir/dracut-functions
	dracut_install poweroff shutdown
	inst_hook emergency 000 ./hard-off.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )
    sudo $basedir/dracut -l -i $TESTDIR/overlay / \
	-o "plymouth network" \
	-a "debug" \
	-d "piix ide-gd_mod ata_piix ext2 sd_mod" \
	-f $TESTDIR/initramfs.testing $KVERSION || return 1
}

test_cleanup() {
    return 0
}

. $testdir/test-functions
