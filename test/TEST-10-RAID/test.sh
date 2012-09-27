#!/bin/bash
TEST_DESCRIPTION="root filesystem on an encrypted LVM PV on a RAID-5"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.udev.log-priority=debug loglevel=70 systemd.log_target=kmsg"
test_run() {
    DISKIMAGE=$TESTDIR/TEST-10-RAID-root.img
    $testdir/run-qemu \
	-hda $DISKIMAGE \
	-m 256M -nographic \
	-net none -kernel /boot/vmlinuz-$KVERSION \
	-append "root=/dev/dracut/root rd.auto rw rd.retry=10 console=ttyS0,115200n81 selinux=0 $DEBUGFAIL" \
	-initrd $TESTDIR/initramfs.testing
    grep -m 1 -q dracut-root-block-success $DISKIMAGE || return 1
}

test_setup() {
    DISKIMAGE=$TESTDIR/TEST-10-RAID-root.img
    # Create the blank file to use as a root filesystem
    rm -f $DISKIMAGE
    dd if=/dev/null of=$DISKIMAGE bs=1M seek=40

    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
	export initdir=$TESTDIR/overlay/source
	(mkdir -p "$initdir"; cd "$initdir"; mkdir -p dev sys proc etc var/run tmp run)
	. $basedir/dracut-functions.sh
	dracut_install sh df free ls shutdown poweroff stty cat ps ln ip route \
	    mount dmesg ifconfig dhclient mkdir cp ping dhclient
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
	    [ -f ${_terminfodir}/l/linux ] && break
	done
	dracut_install -o ${_terminfodir}/l/linux
	inst ./test-init.sh /sbin/init
	inst "$basedir/modules.d/40network/dhclient-script.sh" "/sbin/dhclient-script"
	inst "$basedir/modules.d/40network/ifup.sh" "/sbin/ifup"
	dracut_install grep
	dracut_install /lib/systemd/systemd-shutdown
	find_binary plymouth >/dev/null && dracut_install plymouth
	cp -a /etc/ld.so.conf* $initdir/etc
	sudo ldconfig -r "$initdir"
    )

    # second, install the files needed to make the root filesystem
    (
	export initdir=$TESTDIR/overlay
	. $basedir/dracut-functions.sh
	dracut_install sfdisk mke2fs poweroff cp umount
	inst_hook initqueue 01 ./create-root.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    $basedir/dracut.sh -l -i $TESTDIR/overlay / \
	-m "dash crypt lvm mdraid udev-rules base rootfs-block kernel-modules" \
	-d "piix ide-gd_mod ata_piix ext2 sd_mod" \
        --nomdadmconf \
	-f $TESTDIR/initramfs.makeroot $KVERSION || return 1
    rm -rf $TESTDIR/overlay
    # Invoke KVM and/or QEMU to actually create the target filesystem.
    $testdir/run-qemu \
	-hda $DISKIMAGE \
	-m 256M -nographic -net none \
	-kernel "/boot/vmlinuz-$kernel" \
	-append "root=/dev/dracut/root rw rootfstype=ext2 quiet console=ttyS0,115200n81 selinux=0" \
	-initrd $TESTDIR/initramfs.makeroot  || return 1
    grep -m 1 -q dracut-root-block-created $DISKIMAGE || return 1
    eval $(grep -a -m 1 ID_FS_UUID $DISKIMAGE)

    (
	export initdir=$TESTDIR/overlay
	. $basedir/dracut-functions.sh
	dracut_install poweroff shutdown
	inst_hook emergency 000 ./hard-off.sh
	inst ./cryptroot-ask.sh /sbin/cryptroot-ask
        mkdir -p $initdir/etc
        echo "luks-$ID_FS_UUID /dev/md0 /etc/key" > $initdir/etc/crypttab
        echo -n "test" > $initdir/etc/key
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    sudo $basedir/dracut.sh -l -i $TESTDIR/overlay / \
	-o "plymouth network" \
	-a "debug" \
	-d "piix ide-gd_mod ata_piix ext2 sd_mod" \
	-f $TESTDIR/initramfs.testing $KVERSION || return 1
}

test_cleanup() {
    return 0
}

. $testdir/test-functions
