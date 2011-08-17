#!/bin/bash
TEST_DESCRIPTION="root filesystem on a LiveCD dmsquash filesystem"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"

test_run() {
    $testdir/run-qemu -boot order=d -cdrom livecd.iso -hda root.img -m 256M -nographic \
	-net none -kernel /boot/vmlinuz-$KVERSION \
	-append "root=live:CDLABEL=LiveCD live rw quiet rd.retry=3 rd.info console=ttyS0,115200n81 selinux=0 rd.debug $DEBUGFAIL" \
	-initrd initramfs.testing
    grep -m 1 -q dracut-root-block-success root.img || return 1
}

test_setup() {
    mkdir -p overlay
    (
	initdir=overlay
	. $basedir/dracut-functions
	dracut_install poweroff shutdown
	inst_hook emergency 000 ./hard-off.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    dd if=/dev/null of=root.img seek=100

    sudo $basedir/dracut -l -i overlay / \
	-a "debug" \
	-d "piix ide-gd_mod ata_piix ext3 sd_mod" \
	-f initramfs.testing $KVERSION || return 1

    mkdir -p root-source
    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
	initdir=root-source
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
	inst ./initramfs.testing "/boot/initramfs-$KVERSION.img"
	inst /boot/vmlinuz-$KVERSION
	find_binary plymouth >/dev/null && dracut_install plymouth
	(cd "$initdir"; mkdir -p dev sys proc etc var/run tmp )
	cp -a /etc/ld.so.conf* $initdir/etc
	sudo ldconfig -r "$initdir"
    )
    python create.py -d -c livecd-fedora-minimal.ks
    exit 0
}

test_cleanup() {
    rm -fr overlay root-source
    rm -f root.img initramfs.makeroot initramfs.testing livecd.iso
}

. $testdir/test-functions
