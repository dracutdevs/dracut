#!/bin/bash
TEST_DESCRIPTION="root filesystem on LVM PV on a isw dmraid"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rdinitdebug rdnetdebug"

client_run() {
    echo "CLIENT TEST START: $@"
    $testdir/run-qemu -hda root.ext2 -hdb disk1 -hdc disk2 -m 256M -nographic \
	-net none -kernel /boot/vmlinuz-$KVERSION \
	-append "$@ root=LABEL=root rw quiet rdinfo console=ttyS0,115200n81 rdshell $DEBUGFAIL" \
	-initrd initramfs.testing
    if ! grep -m 1 -q dracut-root-block-success root.ext2; then
	echo "CLIENT TEST END: $@ [FAIL]"
	return 1;
    fi

    sed -i -e 's#dracut-root-block-success#dracut-root-block-xxxxxxx#' root.ext2
    echo "CLIENT TEST END: $@ [OK]"
    return 0
}

test_run() {
    client_run || return 1
    client_run rd_NO_MDIMSM || return 1
    client_run rd_NO_DM || return 1
    client_run rd_NO_DM rd_NO_MDIMSM rd_NO_MDADMCONF || return 1
    client_run rd_NO_MD rd_NO_MDIMSM  && return 1
    client_run rd_NO_MD && return 1
   return 0
}

test_setup() {
    # Create the blank file to use as a root filesystem
    dd if=/dev/zero of=root.ext2 bs=1M count=1
    dd if=/dev/zero of=disk1 bs=1M count=40
    dd if=/dev/zero of=disk2 bs=1M count=40

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
	inst ./test-init /sbin/init
	find_binary plymouth >/dev/null && dracut_install plymouth
	(cd "$initdir"; mkdir -p dev sys proc etc var/run tmp )
    )
 
    # second, install the files needed to make the root filesystem
    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install sfdisk mke2fs poweroff cp umount 
	inst_simple ./create-root.sh /initqueue/01create-root.sh
    )
 
    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    $basedir/dracut -l -i overlay / \
	-m "dash lvm mdraid dmraid udev-rules base rootfs-block kernel-modules" \
	-d "ata_piix ext2 sd_mod dm-multipath dm-crypt dm-round-robin faulty linear multipath raid0 raid10 raid1 raid456" \
	-f initramfs.makeroot $KVERSION || return 1
    rm -rf overlay
    # Invoke KVM and/or QEMU to actually create the target filesystem.
    $testdir/run-qemu -hda root.ext2 -hdb disk1 -hdc disk2 -m 256M -nographic -net none \
	-kernel "/boot/vmlinuz-$kernel" \
	-append "root=/dev/dracut/root rw rootfstype=ext2 quiet console=ttyS0,115200n81" \
	-initrd initramfs.makeroot  || return 1
    grep -m 1 -q dracut-root-block-created root.ext2 || return 1
    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install poweroff shutdown
	inst_simple ./hard-off.sh /emergency/01hard-off.sh
    )
    sudo $basedir/dracut -l -i overlay / \
	-o "plymouth" \
	-a "debug" \
	-d "ata_piix ext2 sd_mod" \
	-f initramfs.testing $KVERSION || return 1
}

test_cleanup() {
    rm -fr overlay mnt
    rm -f root.ext2 initramfs.makeroot initramfs.testing
    rm -f disk1 disk2
}

. $testdir/test-functions
