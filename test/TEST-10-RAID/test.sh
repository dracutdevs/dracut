TEST_DESCRIPTION="root filesystem on an encrypted LVM PV"

test_run() {
    $testdir/run-qemu -hda root.ext2 -m 512M -nographic \
	-net nic,macaddr=52:54:00:12:34:57 -net socket,mcast=230.0.0.1:1234 \
	-kernel /boot/vmlinuz-$(uname -r) \
	-append "root=/dev/dracut/root rw console=ttyS0,115200n81" \
	-initrd initramfs.testing
}

test_setup() {
    # This script creates a root filesystem on an encrypted LVM PV
    dd if=/dev/zero of=root.ext2 bs=1M count=20

    initdir=overlay/source
    kernel=$(uname -r)
    (
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
	dracut_install sfdisk mke2fs poweroff cp umount e2mkdir
	inst_simple ./halt.sh /pre-pivot/02halt.sh
	inst_simple ./copy-root.sh /pre-pivot/01copy-root.sh
	inst_simple ./create-root.sh /pre-mount/01create-root.sh
    )
 
    # create an initramfs that will create the target root filesystem.
    # We do it this way because creating it directly in the host OS
    # results in cryptsetup not being able to unlock the LVM PV.
    # Probably a bug in cryptsetup, but...
    $basedir/dracut -l -i overlay / \
	-m "dash kernel-modules test crypt lvm mdraid udev-rules base rootfs-block" \
	-d "ata_piix ext2 sd_mod" \
	-f initramfs.makeroot || return 1

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    $testdir/run-qemu -hda root.ext2 -m 512M -nographic -net none \
	-kernel "/boot/vmlinuz-$kernel" \
	-append "root=/dev/dracut/root rw rootfstype=ext2 quiet console=ttyS0,115200n81" \
	-initrd initramfs.makeroot  || return 1

    sudo $basedir/dracut -l -f initramfs.testing  || return 1
}

test_cleanup() {
    rm -fr overlay mnt
    rm -f root.ext2 initramfs.makeroot initramfs.testing
}

. $testdir/test-functions
