#!/bin/bash

TEST_DESCRIPTION="root filesystem on a btrfs filesystem with /usr subvolume"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"

client_run() {
    local test_name="$1"; shift
    local client_opts="$*"

    echo "CLIENT TEST START: $test_name"

    dd if=/dev/zero of=$TESTDIR/result bs=1M count=1
    $testdir/run-qemu \
	-hda $TESTDIR/root.btrfs \
	-hdb $TESTDIR/usr.btrfs \
	-hdc $TESTDIR/result \
	-m 256M -nographic \
	-net none -kernel /boot/vmlinuz-$KVERSION \
	-watchdog ib700 -watchdog-action poweroff \
	-append "root=LABEL=dracut $client_opts quiet rd.retry=3 rd.info console=ttyS0,115200n81 selinux=0 rd.debug $DEBUGFAIL" \
	-initrd $TESTDIR/initramfs.testing

    if (($? != 0)); then
	echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
        return 1
    fi

    if ! grep -m 1 -q dracut-root-block-success $TESTDIR/result; then
	echo "CLIENT TEST END: $test_name [FAILED]"
        return 1
    fi
    echo "CLIENT TEST END: $test_name [OK]"

}

test_run() {
    client_run "no option specified" || return 1
    client_run "readonly root" "ro" || return 1
    client_run "writeable root" "rw" || return 1
    return 0
}

test_setup() {
    rm -f $TESTDIR/root.btrfs
    rm -f $TESTDIR/usr.btrfs
    # Create the blank file to use as a root filesystem
    dd if=/dev/null of=$TESTDIR/root.btrfs bs=1M seek=160
    dd if=/dev/null of=$TESTDIR/usr.btrfs bs=1M seek=160

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
	inst "$basedir/modules.d/40network/dhclient-script.sh" "/sbin/dhclient-script"
	inst "$basedir/modules.d/40network/ifup.sh" "/sbin/ifup"
	dracut_install grep
        inst_simple ./fstab /etc/fstab
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
	dracut_install sfdisk mkfs.btrfs btrfs poweroff cp umount sync
	inst_hook initqueue 01 ./create-root.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    $basedir/dracut.sh -l -i $TESTDIR/overlay / \
	-m "dash udev-rules btrfs base rootfs-block kernel-modules" \
	-d "piix ide-gd_mod ata_piix btrfs sd_mod" \
        --nomdadmconf \
        --nohardlink \
	-f $TESTDIR/initramfs.makeroot $KVERSION || return 1

    # Invoke KVM and/or QEMU to actually create the target filesystem.

#    echo $TESTDIR/overlay
#    echo $TESTDIR/initramfs.makeroot
#exit 1
    rm -rf $TESTDIR/overlay

    $testdir/run-qemu \
	-hda $TESTDIR/root.btrfs \
	-hdb $TESTDIR/usr.btrfs \
	-m 256M -nographic -net none \
	-kernel "/boot/vmlinuz-$kernel" \
	-append "root=/dev/dracut/root rw rootfstype=btrfs quiet console=ttyS0,115200n81 selinux=0" \
	-initrd $TESTDIR/initramfs.makeroot  || return 1
    grep -m 1 -q dracut-root-block-created $TESTDIR/root.btrfs || return 1


    (
	initdir=$TESTDIR/overlay
	. $basedir/dracut-functions.sh
	dracut_install poweroff shutdown
	inst_hook emergency 000 ./hard-off.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )
    sudo $basedir/dracut.sh -l -i $TESTDIR/overlay / \
	-a "debug watchdog" \
        -o "network" \
	-d "piix ide-gd_mod ata_piix btrfs sd_mod ib700wdt" \
	-f $TESTDIR/initramfs.testing $KVERSION || return 1

    rm -rf $TESTDIR/overlay

#	-o "plymouth network md dmraid multipath fips caps crypt btrfs resume dmsquash-live dm"
}

test_cleanup() {
    return 0
}

. $testdir/test-functions
