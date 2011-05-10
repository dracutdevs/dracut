#!/bin/bash
TEST_DESCRIPTION="root filesystem on an encrypted LVM PV on a degraded RAID-5"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
DEBUGFAIL="rd.shell"

client_run() {
    echo "CLIENT TEST START: $@"
    $testdir/run-qemu -hda root.ext2 -m 256M -nographic \
	-net none -kernel /boot/vmlinuz-$KVERSION \
	-append "$@ root=LABEL=root rw quiet rd.retry=3 rd.info console=ttyS0,115200n81 selinux=0 rd.debug  $DEBUGFAIL " \
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
    eval $(grep --binary-files=text -m 1 MD_UUID root.ext2)
    echo "MD_UUID=$MD_UUID"

    client_run || return 1

#    client_run rd.md.conf=0 || return 1

    client_run rd.lvm=0 failme && return 1

    client_run rd.lvm.vg=failme failme && return 1

    client_run rd.lvm.vg=dracut || return 1

#    client_run rd.md.uuid=$MD_UUID rd.md.conf=0 || return 1

    client_run rd.lvm.vg=dummy1 rd.lvm.vg=dracut rd.lvm.vg=dummy2 rd.lvm.conf=0 failme && return 1

#    client_run rd.md.uuid=failme rd.md.conf=0 failme && return 1

    client_run rd.md=0 failme && return 1

#    client_run rd.md.uuid=dummy1 rd.md.uuid=$MD_UUID rd.md.uuid=dummy2 rd.md.conf=0 failme && return 1

    return 0
}

test_setup() {
    # Create the blank file to use as a root filesystem
    dd if=/dev/zero of=root.ext2 bs=1M count=40

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
	cp -a /etc/ld.so.conf* $initdir/etc
	sudo ldconfig -r "$initdir"
    )

    # second, install the files needed to make the root filesystem
    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install sfdisk mke2fs poweroff cp umount dd grep
	inst_hook initqueue 01 ./create-root.sh
 	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
   )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    $basedir/dracut -l -i overlay / \
	-m "dash crypt lvm mdraid udev-rules base rootfs-block kernel-modules" \
	-d "piix ide-gd_mod ata_piix ext2 sd_mod" \
	-f initramfs.makeroot $KVERSION || return 1
    rm -rf overlay
    # Invoke KVM and/or QEMU to actually create the target filesystem.
    $testdir/run-qemu -hda root.ext2 -m 256M -nographic -net none \
	-kernel "/boot/vmlinuz-$kernel" \
	-append "root=/dev/dracut/root rw rootfstype=ext2 quiet console=ttyS0,115200n81 selinux=0" \
	-initrd initramfs.makeroot  || return 1
    grep -m 1 -q dracut-root-block-created root.ext2 || return 1
    eval $(grep --binary-files=text -m 1 MD_UUID root.ext2)
    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install poweroff shutdown
	inst_hook emergency 000 ./hard-off.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
	inst ./cryptroot-ask /sbin/cryptroot-ask
        mkdir -p overlay/etc
        echo "ARRAY /dev/md0 level=raid5 num-devices=3 UUID=$MD_UUID" > overlay/etc/mdadm.conf
    )
    sudo $basedir/dracut -l -i overlay / \
	-o "plymouth network" \
	-a "debug" \
	-d "piix ide-gd_mod ata_piix ext2 sd_mod" \
	-f initramfs.testing $KVERSION || return 1
}

test_cleanup() {
    rm -fr overlay mnt
    rm -f root.ext2 initramfs.makeroot initramfs.testing
}

. $testdir/test-functions
