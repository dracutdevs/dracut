#!/bin/bash
TEST_DESCRIPTION="root filesystem on an encrypted LVM PV"

test_run() {
    $testdir/run-qemu -hda root.ext2 -m 512M -nographic \
	-net none -kernel /boot/vmlinuz-$(uname -r) \
	-append "root=/dev/dracut/root rw console=ttyS0,115200n81" \
	-initrd initramfs.testing
}

test_setup() {
    # Create the blank file to use as a root filesystem
    dd if=/dev/zero of=root.ext2 bs=1M count=20

    kernel=$(uname -r)
    # Create what will eventually be our root filesystem onto an overlay
    (
	initdir=overlay/source
	. $basedir/dracut-functions
	dracut_install sh df free ls shutdown poweroff stty cat ps ln ip route \
	    /lib/terminfo/l/linux mount dmesg ifconfig dhclient mkdir cp ping dhclient 
	inst "$basedir/modules.d/40network/dhclient-script" "/sbin/dhclient-script"
	inst "$basedir/modules.d/40network/ifup" "/sbin/ifup"
	dracut_install grep
	inst $testdir/test-init /sbin/init
	find_binary plymouth >/dev/null && dracut_install plymouth
	(cd "$initdir"; mkdir -p dev sys proc etc var/run tmp )
    )
 
    # second, install the files needed to make the root filesystem
    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install sfdisk mke2fs poweroff cp umount 
	inst_simple ./create-root.sh /pre-mount/01create-root.sh
    )
 
    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    $basedir/dracut -l -i overlay / \
	-m "dash crypt lvm mdraid udev-rules base rootfs-block" \
	-d "ata_piix ext2 sd_mod" \
	-f initramfs.makeroot || return 1

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    $testdir/run-qemu -hda root.ext2 -m 512M -nographic -net none \
	-kernel "/boot/vmlinuz-$kernel" \
	-append "root=/dev/dracut/root rw rootfstype=ext2 quiet console=ttyS0,115200n81" \
	-initrd initramfs.makeroot  || return 1

    sudo $basedir/dracut -l \
	-m "dash crypt lvm mdraid udev-rules base rootfs-block" \
	-d "ata_piix ext2 sd_mod" \
	-f initramfs.testing || return 1
}

test_cleanup() {
    rm -fr overlay mnt
    rm -f root.ext2 initramfs.makeroot initramfs.testing
}

. $testdir/test-functions
