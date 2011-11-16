#!/bin/bash
TEST_DESCRIPTION="root filesystem on a LiveCD dmsquash filesystem"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"

test_run() {
    $testdir/run-qemu \
	-boot order=d \
	-cdrom $TESTDIR/livecd.iso \
	-hda $TESTDIR/root.img \
	-m 256M -nographic \
	-net none -kernel /boot/vmlinuz-$KVERSION \
	-append "root=live:CDLABEL=LiveCD live rw quiet rd.retry=3 rd.info console=ttyS0,115200n81 selinux=0 rd.debug $DEBUGFAIL" \
	-initrd $TESTDIR/initramfs.testing
    grep -m 1 -q dracut-root-block-success $TESTDIR/root.img || return 1
}

test_setup() {
    mkdir -p $TESTDIR/overlay
    (
	initdir=$TESTDIR/overlay
	. $basedir/dracut-functions
	dracut_install poweroff shutdown
	inst_hook emergency 000 ./hard-off.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    dd if=/dev/zero of=$TESTDIR/root.img count=100

    sudo $basedir/dracut -l -i $TESTDIR/overlay / \
	-a "debug dmsquash-live" \
	-d "piix ide-gd_mod ata_piix ext3 sd_mod" \
	-f $TESTDIR/initramfs.testing $KVERSION || return 1

    mkdir -p $TESTDIR/root-source
    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
	initdir=$TESTDIR/root-source
	. $basedir/dracut-functions
	dracut_install sh df free ls shutdown poweroff stty cat ps ln ip route \
	    /lib/terminfo/l/linux mount dmesg ifconfig dhclient mkdir cp ping dhclient \
	    umount strace less
	inst "$basedir/modules.d/40network/dhclient-script" "/sbin/dhclient-script"
	inst "$basedir/modules.d/40network/ifup" "/sbin/ifup"
	dracut_install grep syslinux isohybrid
	for f in /usr/share/syslinux/*; do
	    inst_simple "$f"
	done
	inst ./test-init /sbin/init
	inst $TESTDIR/initramfs.testing "/boot/initramfs-$KVERSION.img"
	inst /boot/vmlinuz-$KVERSION
	find_binary plymouth >/dev/null && dracut_install plymouth
	(cd "$initdir"; mkdir -p dev sys proc etc var/run tmp )
	cp -a /etc/ld.so.conf* $initdir/etc
	sudo ldconfig -r "$initdir"
    )
    python create.py -d -c livecd-fedora-minimal.ks
    return 0
}

test_cleanup() {
    return 0
}

. $testdir/test-functions
