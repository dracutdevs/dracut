#!/bin/bash
TEST_DESCRIPTION="root filesystem on a ext3 filesystem"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"

test_run() {
    $testdir/run-qemu \
	-hda $TESTDIR/root.ext3 \
	-m 256M -nographic \
	-net none -kernel /boot/vmlinuz-$KVERSION \
	-append "root=LABEL=dracut rw quiet rd.retry=3 rd.info console=ttyS0,115200n81 selinux=0 rd.debug $DEBUGFAIL" \
	-initrd $TESTDIR/initramfs.testing
    grep -m 1 -q dracut-root-block-success $TESTDIR/root.ext3 || return 1
}

test_setup() {
    rm -f $TESTDIR/root.ext3
    # Create the blank file to use as a root filesystem
    dd if=/dev/null of=$TESTDIR/root.ext3 bs=1M seek=40

    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
	initdir=$TESTDIR/overlay/source
	mkdir -p $initdir
	. $basedir/dracut-functions.sh
	dracut_install sh df free ls shutdown poweroff stty cat ps ln ip route \
	    mount dmesg ifconfig dhclient mkdir cp ping dhclient \
	    umount strace less setsid
	for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
	done
	dracut_install -o ${_terminfodir}/l/linux
	inst "$basedir/modules.d/40network/dhclient-script" "/sbin/dhclient-script"
	inst "$basedir/modules.d/40network/ifup" "/sbin/ifup"
	dracut_install grep
	inst ./test-init.sh /sbin/init
	find_binary plymouth >/dev/null && dracut_install plymouth
	(cd "$initdir"; mkdir -p dev sys proc etc var/run tmp )
	cp -a /etc/ld.so.conf* $initdir/etc
	sudo ldconfig -r "$initdir"
    )

    # second, install the files needed to make the root filesystem
    (
	initdir=$TESTDIR/overlay
	. $basedir/dracut-functions.sh
	dracut_install sfdisk mkfs.ext3 poweroff cp umount sync
	inst_hook initqueue 01 ./create-root.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    $basedir/dracut.sh -l -i $TESTDIR/overlay / \
	-m "dash udev-rules base rootfs-block kernel-modules" \
	-d "piix ide-gd_mod ata_piix ext3 sd_mod" \
        --nomdadmconf \
	-f $TESTDIR/initramfs.makeroot $KVERSION || return 1
    rm -rf $TESTDIR/overlay
    # Invoke KVM and/or QEMU to actually create the target filesystem.

    $testdir/run-qemu \
	-hda $TESTDIR/root.ext3 \
	-m 256M -nographic -net none \
	-kernel "/boot/vmlinuz-$kernel" \
	-append "root=/dev/dracut/root rw rootfstype=ext3 quiet console=ttyS0,115200n81 selinux=0" \
	-initrd $TESTDIR/initramfs.makeroot  || return 1
    grep -m 1 -q dracut-root-block-created $TESTDIR/root.ext3 || return 1


    (
	initdir=$TESTDIR/overlay
	. $basedir/dracut-functions.sh
	dracut_install poweroff shutdown
	inst_hook emergency 000 ./hard-off.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )
    sudo $basedir/dracut.sh -l -i $TESTDIR/overlay / \
	-a "debug" \
	-d "piix ide-gd_mod ata_piix ext3 sd_mod" \
	-f $TESTDIR/initramfs.testing $KVERSION || return 1

#	-o "plymouth network md dmraid multipath fips caps crypt btrfs resume dmsquash-live dm"
}

test_cleanup() {
    return 0
}

. $testdir/test-functions
