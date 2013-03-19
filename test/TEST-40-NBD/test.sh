#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
TEST_DESCRIPTION="root filesystem on NBD"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.retry=10 rd.break"
#SERIAL="udp:127.0.0.1:9999"
SERIAL="null"

run_server() {
    # Start server first
    echo "NBD TEST SETUP: Starting DHCP/NBD server"

    $testdir/run-qemu \
        -hda $TESTDIR/server.ext2 \
        -hdb $TESTDIR/nbd.ext2 \
        -hdc $TESTDIR/encrypted.ext2 \
        -m 256M -smp 2 -nographic \
        -net nic,macaddr=52:54:00:12:34:56,model=e1000 \
        -net socket,listen=127.0.0.1:12340 \
        -serial $SERIAL \
        -kernel /boot/vmlinuz-$KVERSION \
        -append "root=/dev/sda rootfstype=ext2 rw quiet console=ttyS0,115200n81 selinux=0" \
        -initrd $TESTDIR/initramfs.server -pidfile $TESTDIR/server.pid -daemonize || return 1
    sudo chmod 644 $TESTDIR/server.pid || return 1

    # Cleanup the terminal if we have one
    tty -s && stty sane

    echo Sleeping 10 seconds to give the server a head start
    sleep 10
}

client_test() {
    local test_name="$1"
    local mac=$2
    local cmdline="$3"
    local fstype=$4
    local fsopt=$5
    local found opts nbdinfo

    [[ $fstype ]] || fstype=ext3
    [[ $fsopt ]] || fsopt="ro"

    echo "CLIENT TEST START: $test_name"

    # Clear out the flags for each test
    if ! dd if=/dev/zero of=$TESTDIR/flag.img bs=1M count=1; then
        echo "Unable to make client sda image" 1>&2
        return 1
    fi

    $testdir/run-qemu \
        -hda $TESTDIR/flag.img \
        -m 512M -smp 2 \
        -nographic \
        -net nic,macaddr=$mac,model=e1000 \
        -net socket,connect=127.0.0.1:12340 \
        -kernel /boot/vmlinuz-$KVERSION \
        -append "$cmdline $DEBUGFAIL rd.auto rd.info rd.retry=10 ro console=ttyS0,115200n81  selinux=0  " \
        -initrd $TESTDIR/initramfs.testing

    if [[ $? -ne 0 ]] || ! grep -m 1 -q nbd-OK $TESTDIR/flag.img; then
        echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
        return 1
    fi

    # nbdinfo=( fstype fsoptions )
    nbdinfo=($(awk '{print $2, $3; exit}' $TESTDIR/flag.img))

    if [[ "${nbdinfo[0]}" != "$fstype" ]]; then
        echo "CLIENT TEST END: $test_name [FAILED - WRONG FS TYPE] \"${nbdinfo[0]}\" != \"$fstype\""
        return 1
    fi

    opts=${nbdinfo[1]},
    while [[ $opts ]]; do
        if [[ ${opts%%,*} = $fsopt ]]; then
            found=1
            break
        fi
        opts=${opts#*,}
    done

    if [[ ! $found ]]; then
        echo "CLIENT TEST END: $test_name [FAILED - BAD FS OPTS] \"${nbdinfo[1]}\" != \"$fsopt\""
        return 1
    fi

    echo "CLIENT TEST END: $test_name [OK]"
}

test_run() {
    modinfo nbd &>/dev/null || { echo "Kernel does not support nbd"; exit 1; }
    if ! run_server; then
        echo "Failed to start server" 1>&2
        return 1
    fi
    client_run
    kill_server
}

client_run() {
    # The default is ext3,errors=continue so use that to determine
    # if our options were parsed and used
    client_test "NBD root=nbd:IP:port::fsopts" 52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:2000::errors=panic rd.luks=0" \
        ext3 errors=panic || return 1

    client_test "NBD root=nbd:IP:port" 52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:2000 rd.luks=0" || return 1

    client_test "NBD root=nbd:IP:port:fstype" 52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:2000:ext2 rd.luks=0" ext2 || return 1

    client_test "NBD root=nbd:IP:port:fstype:fsopts" 52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:2000:ext2:errors=panic rd.luks=0" \
        ext2 errors=panic || return 1

    client_test "NBD Bridge root=nbd:IP:port:fstype:fsopts" 52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:2000:ext2:errors=panic bridge rd.luks=0" \
        ext2 errors=panic || return 1

     # There doesn't seem to be a good way to validate the NBD options, so
     # just check that we don't screw up the other options

    client_test "NBD root=nbd:IP:port:::NBD opts" 52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:2000:::bs=2048 rd.luks=0" || return 1

    client_test "NBD root=nbd:IP:port:fstype::NBD opts" 52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:2000:ext2::bs=2048 rd.luks=0" ext2 || return 1

    client_test "NBD root=nbd:IP:port:fstype:fsopts:NBD opts" \
        52:54:00:12:34:00 \
        "root=nbd:192.168.50.1:2000:ext2:errors=panic:bs=2048 rd.luks=0" \
        ext2 errors=panic || return 1

    # DHCP root-path parsing

    client_test "NBD root=dhcp DHCP root-path nbd:srv:port" 52:54:00:12:34:01 \
        "root=dhcp rd.luks=0" || return 1

    client_test "NBD Bridge root=dhcp DHCP root-path nbd:srv:port" 52:54:00:12:34:01 \
        "root=dhcp bridge rd.luks=0" || return 1

    client_test "NBD root=dhcp DHCP root-path nbd:srv:port:fstype" \
        52:54:00:12:34:02 "root=dhcp rd.luks=0" ext2 || return 1

    client_test "NBD root=dhcp DHCP root-path nbd:srv:port::fsopts" \
        52:54:00:12:34:03 "root=dhcp rd.luks=0" ext3 errors=panic || return 1

    client_test "NBD root=dhcp DHCP root-path nbd:srv:port:fstype:fsopts" \
        52:54:00:12:34:04 "root=dhcp rd.luks=0" ext2 errors=panic || return 1

    # netroot handling

    client_test "NBD netroot=nbd:IP:port" 52:54:00:12:34:00 \
        "netroot=nbd:192.168.50.1:2000 rd.luks=0" || return 1

    client_test "NBD netroot=dhcp DHCP root-path nbd:srv:port:fstype:fsopts" \
        52:54:00:12:34:04 "netroot=dhcp rd.luks=0" ext2 errors=panic || return 1

    # Encrypted root handling via LVM/LUKS over NBD

    . $TESTDIR/luks.uuid

    client_test "NBD root=LABEL=dracut netroot=nbd:IP:port" \
        52:54:00:12:34:00 \
        "root=LABEL=dracut rd.luks.uuid=$ID_FS_UUID rd.lv.vg=dracut netroot=nbd:192.168.50.1:2001" || return 1

    # XXX This should be ext2,errors=panic but that doesn't currently
    # XXX work when you have a real root= line in addition to netroot=
    # XXX How we should work here needs clarification
    client_test "NBD root=LABEL=dracut netroot=dhcp (w/ fstype and opts)" \
        52:54:00:12:34:05 \
        "root=LABEL=dracut rd.luks.uuid=$ID_FS_UUID rd.lv.vg=dracut netroot=dhcp" || return 1

    if [[ -s server.pid ]]; then
        sudo kill -TERM $(cat $TESTDIR/server.pid)
        rm -f $TESTDIR/server.pid
    fi

}

make_encrypted_root() {
    # Create the blank file to use as a root filesystem
    dd if=/dev/null of=$TESTDIR/encrypted.ext2 bs=1M seek=20
    dd if=/dev/null of=$TESTDIR/flag.img bs=1M seek=1

    kernel=$KVERSION
    # Create what will eventually be our root filesystem onto an overlay
    (
        export initdir=$TESTDIR/overlay/source
        . $basedir/dracut-functions.sh
        mkdir -p "$initdir"
        (cd "$initdir"; mkdir -p dev sys proc etc var/run tmp )
        dracut_install sh df free ls shutdown poweroff stty cat ps ln ip \
            mount dmesg mkdir cp ping
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        dracut_install -o ${_terminfodir}/l/linux
        inst ./client-init.sh /sbin/init
        find_binary plymouth >/dev/null && dracut_install plymouth
        cp -a /etc/ld.so.conf* $initdir/etc
        sudo ldconfig -r "$initdir"
    )

    # second, install the files needed to make the root filesystem
    (
        export initdir=$TESTDIR/overlay
        . $basedir/dracut-functions.sh
        dracut_install mke2fs poweroff cp umount tune2fs
        inst_hook emergency 000 ./hard-off.sh
        inst_hook initqueue 01 ./create-root.sh
        inst_hook initqueue/finished 01 ./finished-false.sh
        inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
    )

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    $basedir/dracut.sh -l -i $TESTDIR/overlay / \
        -m "dash crypt lvm mdraid udev-rules base rootfs-block kernel-modules" \
        -d "piix ide-gd_mod ata_piix ext2 ext3 sd_mod" \
        -f $TESTDIR/initramfs.makeroot $KVERSION || return 1
    rm -rf $TESTDIR/overlay

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    $testdir/run-qemu \
        -hda $TESTDIR/flag.img \
        -hdb $TESTDIR/encrypted.ext2 \
        -m 256M -smp 2\
        -nographic -net none \
        -kernel "/boot/vmlinuz-$kernel" \
        -append "root=/dev/fakeroot rw quiet console=ttyS0,115200n81 selinux=0" \
        -initrd $TESTDIR/initramfs.makeroot  || return 1
    grep -m 1 -q dracut-root-block-created $TESTDIR/flag.img || return 1
    grep -a -m 1 ID_FS_UUID $TESTDIR/flag.img > $TESTDIR/luks.uuid
}

make_client_root() {
    dd if=/dev/null of=$TESTDIR/nbd.ext2 bs=1M seek=30
    mke2fs -F -j $TESTDIR/nbd.ext2
    mkdir $TESTDIR/mnt
    sudo mount -o loop $TESTDIR/nbd.ext2 $TESTDIR/mnt

    kernel=$KVERSION
    (
        export initdir=$TESTDIR/mnt
        . $basedir/dracut-functions.sh
        mkdir -p "$initdir"
        (cd "$initdir"; mkdir -p dev sys proc etc var/run tmp )
        dracut_install sh ls shutdown poweroff stty cat ps ln ip \
            dmesg mkdir cp ping
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        dracut_install -o ${_terminfodir}/l/linux
        inst ./client-init.sh /sbin/init
        inst /etc/nsswitch.conf /etc/nsswitch.conf
        inst /etc/passwd /etc/passwd
        inst /etc/group /etc/group
        for i in /usr/lib*/libnss_files* /lib*/libnss_files*;do
            [ -e "$i" ] || continue
            inst $i
        done
        cp -a /etc/ld.so.conf* $initdir/etc
        sudo ldconfig -r "$initdir"
    )

    sudo umount $TESTDIR/mnt
    rm -fr $TESTDIR/mnt
}

make_server_root() {
    dd if=/dev/null of=$TESTDIR/server.ext2 bs=1M seek=30
    mke2fs -F $TESTDIR/server.ext2
    mkdir $TESTDIR/mnt
    sudo mount -o loop $TESTDIR/server.ext2 $TESTDIR/mnt

    kernel=$KVERSION
    (
        export initdir=$TESTDIR/mnt
        . $basedir/dracut-functions.sh
        mkdir -p "$initdir"
        (
            cd "$initdir";
            mkdir -p dev sys proc etc var/run var/lib/dhcpd tmp
        )
        dracut_install sh ls shutdown poweroff stty cat ps ln ip \
            dmesg mkdir cp ping grep \
            sleep nbd-server chmod
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        dracut_install -o ${_terminfodir}/l/linux
        instmods af_packet
        type -P dhcpd >/dev/null && dracut_install dhcpd
        [ -x /usr/sbin/dhcpd3 ] && inst /usr/sbin/dhcpd3 /usr/sbin/dhcpd
        inst ./server-init.sh /sbin/init
        inst ./hosts /etc/hosts
        inst ./dhcpd.conf /etc/dhcpd.conf
        inst /etc/nsswitch.conf /etc/nsswitch.conf
        inst /etc/passwd /etc/passwd
        inst /etc/group /etc/group
        for i in /usr/lib*/libnss_files* /lib*/libnss_files*;do
            [ -e "$i" ] || continue
            inst $i
        done

        cp -a /etc/ld.so.conf* $initdir/etc
        sudo ldconfig -r "$initdir"
    )

    sudo umount $TESTDIR/mnt
    rm -fr $TESTDIR/mnt
}

test_setup() {

    modinfo nbd &>/dev/null || { echo "Kernel does not support nbd"; exit 1; }

    make_encrypted_root || return 1
    make_client_root || return 1
    make_server_root || return 1

    # Make the test image
    (
        export initdir=$TESTDIR/overlay
        . $basedir/dracut-functions.sh
        dracut_install poweroff shutdown
        inst_hook emergency 000 ./hard-off.sh
        inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
        inst ./cryptroot-ask.sh /sbin/cryptroot-ask

#        inst ./debug-shell.service /lib/systemd/system/debug-shell.service
#        mkdir -p "${initdir}/lib/systemd/system/sysinit.target.wants"
#        ln -fs ../debug-shell.service "${initdir}/lib/systemd/system/sysinit.target.wants/debug-shell.service"

        . $TESTDIR/luks.uuid
        mkdir -p $initdir/etc
        echo "luks-$ID_FS_UUID /dev/nbd0 /etc/key" > $initdir/etc/crypttab
        echo -n test > $initdir/etc/key
    )

    sudo $basedir/dracut.sh -l -i $TESTDIR/overlay / \
        -m "dash udev-rules rootfs-block base debug kernel-modules" \
        -d "af_packet piix ide-gd_mod ata_piix ext2 ext3 sd_mod e1000" \
        -f $TESTDIR/initramfs.server $KVERSION || return 1

    sudo $basedir/dracut.sh -l -i $TESTDIR/overlay / \
        -o "plymouth" \
        -a "debug watchdog" \
        -d "af_packet piix ide-gd_mod ata_piix ext2 ext3 sd_mod e1000 i6300esbwdt" \
        -f $TESTDIR/initramfs.testing $KVERSION || return 1
}

kill_server() {
    if [[ -s $TESTDIR/server.pid ]]; then
        sudo kill -TERM $(cat $TESTDIR/server.pid)
        rm -f $TESTDIR/server.pid
    fi
}

test_cleanup() {
    kill_server
}

. $testdir/test-functions
