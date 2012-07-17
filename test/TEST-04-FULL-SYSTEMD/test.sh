#!/bin/bash

TEST_DESCRIPTION="Full systemd serialization/deserialization test with /usr mount"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break"
#DEBUGFAIL="rd.shell"
#DEBUGOUT="quiet systemd.log_level=debug systemd.log_target=console loglevel=77  rd.info rd.debug"
DEBUGOUT="loglevel=0 systemd.log_level=debug systemd.log_target=kmsg"
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
	-append "root=LABEL=dracut $client_opts rd.retry=3 console=ttyS0,115200n81 selinux=0 $DEBUGOUT $DEBUGFAIL" \
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
    dd if=/dev/null of=$TESTDIR/root.btrfs bs=1M seek=320
    dd if=/dev/null of=$TESTDIR/usr.btrfs bs=1M seek=320

    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
	export initdir=$TESTDIR/overlay/source
	mkdir -p $initdir
	. $basedir/dracut-functions.sh

        for d in usr/bin usr/sbin bin etc lib "$libdir" sbin tmp usr var var/log dev proc sys sysroot root run; do
            if [ -L "/$d" ]; then
                inst_symlink "/$d"
            else
                inst_dir "/$d"
            fi
        done

        ln -sfn /run "$initdir/var/run"
        ln -sfn /run/lock "$initdir/var/lock"

	dracut_install sh df free ls shutdown poweroff stty cat ps ln ip route \
	    mount dmesg ifconfig dhclient mkdir cp ping dhclient \
	    umount strace less setsid tree systemctl

	for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
	done
	dracut_install -o ${_terminfodir}/l/linux
	inst "$basedir/modules.d/40network/dhclient-script.sh" "/sbin/dhclient-script"
	inst "$basedir/modules.d/40network/ifup.sh" "/sbin/ifup"
	dracut_install grep
        inst_simple ./fstab /etc/fstab
        rpm -ql systemd | xargs -r $DRACUT_INSTALL ${initdir+-D "$initdir"} -o -a -l
        inst /lib/systemd/system/systemd-journal-flush.service
        inst /etc/sysconfig/init
        # activate kmsg import
        echo 'ImportKernel=yes' >> $initdir/etc/systemd/journald.conf

        # make a journal directory
        mkdir -p $initdir/var/log/journal

        # install some basic config files
        dracut_install -o  \
            /etc/sysconfig/init \
            /etc/passwd \
            /etc/shadow \
            /etc/group \
            /etc/shells \
            /etc/nsswitch.conf \
            /etc/pam.conf \
            /etc/securetty \
            /etc/os-release \
            /etc/localtime

        # we want an empty environment
        > $initdir/etc/environment
        > $initdir/etc/machine-id

        # set the hostname
        echo  systemd-testsuite > $initdir/etc/hostname

        # setup the testsuite target
        cat >$initdir/etc/systemd/system/testsuite.target <<EOF
[Unit]
Description=Testsuite target
Requires=basic.target
After=basic.target
Conflicts=rescue.target
AllowIsolate=yes
EOF

        inst ./test-init.sh /sbin/test-init

        # setup the testsuite service
        cat >$initdir/etc/systemd/system/testsuite.service <<EOF
[Unit]
Description=Testsuite service
After=basic.target

[Service]
ExecStart=/sbin/test-init
ExecStopPost=/usr/bin/systemctl poweroff
Type=oneshot
StandardInput=tty
StandardOutput=tty
EOF
        mkdir -p $initdir/etc/systemd/system/testsuite.target.wants
        ln -fs ../testsuite.service $initdir/etc/systemd/system/testsuite.target.wants/testsuite.service

        # make the testsuite the default target
        ln -fs testsuite.target $initdir/etc/systemd/system/default.target
        mkdir -p $initdir/etc/rc.d
        cat >$initdir/etc/rc.d/rc.local <<EOF
#!/bin/bash
exit 0
EOF

        # install basic tools needed
        dracut_install sh bash setsid loadkeys setfont \
            login sushell sulogin gzip sleep echo mount umount
        dracut_install modprobe

        # install libnss_files for login
        inst_libdir_file "libnss_files*"

        # install dbus and pam
        find \
            /etc/dbus-1 \
            /etc/pam.d \
            /etc/security \
            /lib64/security \
            /lib/security -xtype f \
            | while read file; do
            dracut_install -o $file
        done

        # install dbus socket and service file
        inst /usr/lib/systemd/system/dbus.socket
        inst /usr/lib/systemd/system/dbus.service

        # install basic keyboard maps and fonts
        for i in \
            /usr/lib/kbd/consolefonts/latarcyrheb-sun16* \
            /usr/lib/kbd/keymaps/include/* \
            /usr/lib/kbd/keymaps/i386/include/* \
            /usr/lib/kbd/keymaps/i386/qwerty/us.*; do
                [[ -f $i ]] || continue
                inst $i
        done

        # some basic terminfo files
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        dracut_install -o ${_terminfodir}/l/linux

        # softlink mtab
        ln -fs /proc/self/mounts $initdir/etc/mtab

        # install any Exec's from the service files
        egrep -ho '^Exec[^ ]*=[^ ]+' $initdir/lib/systemd/system/*.service \
            | while read i; do
            i=${i##Exec*=}; i=${i##-}
            dracut_install -o $i
        done

        # some helper tools for debugging
        [[ $DEBUGTOOLS ]] && dracut_install $DEBUGTOOLS

        # install ld.so.conf* and run ldconfig
        cp -a /etc/ld.so.conf* $initdir/etc
        ldconfig -r "$initdir"
        ddebug "Strip binaeries"
        find "$initdir" -perm +111 -type f | xargs strip --strip-unneeded | ddebug

        # copy depmod files
        inst /lib/modules/$KERNEL_VER/modules.order
        inst /lib/modules/$KERNEL_VER/modules.builtin
        # generate module dependencies
        if [[ -d $initdir/lib/modules/$KERNEL_VER ]] && \
            ! depmod -a -b "$initdir" $KERNEL_VER; then
                dfatal "\"depmod -a $KERNEL_VER\" failed."
                exit 1
        fi

    )
#exit 1
    # second, install the files needed to make the root filesystem
    (
	export initdir=$TESTDIR/overlay
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
	export initdir=$TESTDIR/overlay
	. $basedir/dracut-functions.sh
	dracut_install poweroff shutdown
	inst_hook emergency 000 ./hard-off.sh
	inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )
    sudo $basedir/dracut.sh -l -i $TESTDIR/overlay / \
	-a "debug watchdog systemd" \
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
