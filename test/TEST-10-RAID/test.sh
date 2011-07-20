#!/bin/bash
TEST_DESCRIPTION="root filesystem on an encrypted LVM PV on a RAID-5"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell"
DISKIMAGE=/var/tmp/TEST-10-RAID-root.img
test_run() {
    $testdir/run-qemu -hda $DISKIMAGE -m 256M -nographic \
	-net none -kernel /boot/vmlinuz-$KVERSION \
	-append "root=/dev/dracut/root rw quiet rd.retry=3 rd.info console=ttyS0,115200n81 selinux=0 rd.debug  $DEBUGFAIL" \
	-initrd initramfs.testing
    grep -m 1 -q dracut-root-block-success $DISKIMAGE || return 1
}

test_setup() {
    # Create the blank file to use as a root filesystem
    dd if=/dev/null of=$DISKIMAGE bs=1M seek=40

    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
	initdir=overlay/source
	. $basedir/dracut-functions
	dracut_install sh df free ls shutdown poweroff stty cat ps ln ip route \
	    /lib/terminfo/l/linux mount dmesg ifconfig dhclient mkdir cp ping dhclient
	inst "$basedir/modules.d/40network/dhclient-script" "/sbin/dhclient-script"
	inst "$basedir/modules.d/40network/ifup" "/sbin/ifup"
	dracut_install grep
	dracut_install /lib/systemd/systemd-shutdown
	inst ./test-init /sbin/init
	find_binary plymouth >/dev/null && dracut_install plymouth
	(cd "$initdir"; mkdir -p dev sys proc etc var/run tmp run)
	cp -a /etc/ld.so.conf* $initdir/etc
	sudo ldconfig -r "$initdir"
    )

    # second, install the files needed to make the root filesystem
    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install sfdisk mke2fs poweroff cp umount
	inst_hook initqueue 01 ./create-root.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    $basedir/dracut -l -i overlay / \
	-m "dash crypt lvm mdraid udev-rules base rootfs-block kernel-modules" \
	-d "piix ide-gd_mod ata_piix ext2 sd_mod" \
        --nomdadmconf \
	-f initramfs.makeroot $KVERSION || return 1
    rm -rf overlay
    # Invoke KVM and/or QEMU to actually create the target filesystem.
    $testdir/run-qemu -hda $DISKIMAGE -m 256M -nographic -net none \
	-kernel "/boot/vmlinuz-$kernel" \
	-append "root=/dev/dracut/root rw rootfstype=ext2 quiet console=ttyS0,115200n81 selinux=0" \
	-initrd initramfs.makeroot  || return 1
    grep -m 1 -q dracut-root-block-created $DISKIMAGE || return 1
    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install poweroff shutdown
	inst_hook emergency 000 ./hard-off.sh
	inst ./cryptroot-ask /sbin/cryptroot-ask
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )
    sudo $basedir/dracut -l -i overlay / \
	-o "plymouth network" \
	-a "debug" \
	-d "piix ide-gd_mod ata_piix ext2 sd_mod" \
	-f initramfs.testing $KVERSION || return 1
}

test_cleanup() {
    rm -fr overlay mnt
    rm -f $DISKIMAGE initramfs.makeroot initramfs.testing
}

. $testdir/test-functions
