#!/bin/bash
TEST_DESCRIPTION="root filesystem on a ext3 filesystem"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"

test_run() {
    $testdir/run-qemu -hda root.ext3 -m 256M -nographic \
	-net none -kernel /boot/vmlinuz-$KVERSION \
	-append "root=LABEL=dracut rw quiet rd.retry=3 rd.info console=ttyS0,115200n81 selinux=0 rd.debug $DEBUGFAIL" \
	-initrd initramfs.testing
    grep -m 1 -q dracut-root-block-success root.ext3 || return 1
}

test_setup() {
    
    if [ ! -e root.ext3 ]; then

    # Create the blank file to use as a root filesystem
	dd if=/dev/zero of=root.ext3 bs=1M count=40

	kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
	(
	    initdir=overlay/source
	    . $basedir/dracut-functions
	    dracut_install sh df free ls shutdown poweroff stty cat ps ln ip route \
		/lib/terminfo/l/linux mount dmesg ifconfig dhclient mkdir cp ping dhclient \
		umount strace less
	    inst "$basedir/modules.d/40network/dhclient-script" "/sbin/dhclient-script"
	    inst "$basedir/modules.d/40network/ifup" "/sbin/ifup"
	    dracut_install grep
	    inst ./test-init /sbin/init
	    find_binary plymouth >/dev/null && dracut_install plymouth
	    (cd "$initdir"; mkdir -p dev sys proc etc var/run tmp )
	    cp -a /etc/ld.so.conf* $initdir/etc
	    sudo ldconfig -r "$initdir"
	)
	
    # second, install the files needed to make the root filesystem
	(
	    initdir=overlay
	    . $basedir/dracut-functions
	    dracut_install sfdisk mkfs.ext3 poweroff cp umount 
	    inst_hook initqueue 01 ./create-root.sh
	    inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
	)
	
    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
	$basedir/dracut -l -i overlay / \
	    -m "dash udev-rules base rootfs-block kernel-modules" \
	    -d "piix ide-gd_mod ata_piix ext3 sd_mod" \
            --nomdadmconf \
	    -f initramfs.makeroot $KVERSION || return 1
	rm -rf overlay
    # Invoke KVM and/or QEMU to actually create the target filesystem.
	$testdir/run-qemu -hda root.ext3 -m 256M -nographic -net none \
	    -kernel "/boot/vmlinuz-$kernel" \
	    -append "root=/dev/dracut/root rw rootfstype=ext3 quiet console=ttyS0,115200n81 selinux=0" \
	    -initrd initramfs.makeroot  || return 1
	grep -m 1 -q dracut-root-block-created root.ext3 || return 1
    fi

    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install poweroff shutdown
	inst_hook emergency 000 ./hard-off.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )
    sudo $basedir/dracut -l -i overlay / \
	-a "debug" \
	-d "piix ide-gd_mod ata_piix ext3 sd_mod" \
	-f initramfs.testing $KVERSION || return 1

#	-o "plymouth network md dmraid multipath fips caps crypt btrfs resume dmsquash-live dm" 
}

test_cleanup() {
    rm -fr overlay mnt
    rm -f root.ext3 initramfs.makeroot initramfs.testing
}

. $testdir/test-functions
