#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem over iSCSI with $USE_NETWORK"

#DEBUGFAIL="rd.shell rd.break rd.debug loglevel=7 "
#SERVER_DEBUG="rd.debug loglevel=7"
#SERIAL="tcp:127.0.0.1:9999"

run_server() {
    # Start server first
    echo "iSCSI TEST SETUP: Starting DHCP/iSCSI server"

    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/server.img serverroot 0 1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/singleroot.img singleroot
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid0-1.img raid0-1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid0-2.img raid0-2

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -serial "${SERIAL:-"file:$TESTDIR/server.log"}" \
        -net nic,macaddr=52:54:00:12:34:56,model=e1000 \
        -net nic,macaddr=52:54:00:12:34:57,model=e1000 \
        -net socket,listen=127.0.0.1:12330 \
        -append "panic=1 oops=panic softlockup_panic=1 quiet root=/dev/disk/by-id/ata-disk_serverroot rootfstype=ext4 rw console=ttyS0,115200n81 selinux=0 $SERVER_DEBUG" \
        -initrd "$TESTDIR"/initramfs.server \
        -pidfile "$TESTDIR"/server.pid -daemonize || return 1
    chmod 644 "$TESTDIR"/server.pid || return 1

    # Cleanup the terminal if we have one
    tty -s && stty sane

    if ! [[ $SERIAL ]]; then
        while :; do
            grep Serving "$TESTDIR"/server.log && break
            echo "Waiting for the server to startup"
            tail "$TESTDIR"/server.log
            sleep 1
        done
    else
        echo Sleeping 10 seconds to give the server a head start
        sleep 10
    fi

}

run_client() {
    local test_name=$1
    shift
    echo "CLIENT TEST START: $test_name"

    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker

    test_marker_reset
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -net nic,macaddr=52:54:00:12:34:00,model=e1000 \
        -net nic,macaddr=52:54:00:12:34:01,model=e1000 \
        -net socket,connect=127.0.0.1:12330 \
        -acpitable file=ibft.table \
        -append "$*" \
        -initrd "$TESTDIR"/initramfs.testing

    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]] || ! test_marker_check iscsi-OK; then
        echo "CLIENT TEST END: $test_name [FAILED - BAD EXIT]"
        return 1
    fi

    echo "CLIENT TEST END: $test_name [OK]"
    return 0
}

do_test_run() {
    initiator=$(iscsi-iname)

    run_client "root=dhcp" \
        "root=/dev/root netroot=dhcp ip=enp0s1:dhcp" \
        "rd.iscsi.initiator=$initiator" \
        || return 1

    run_client "netroot=iscsi target0" \
        "root=LABEL=singleroot netroot=iscsi:192.168.50.1::::iqn.2009-06.dracut:target0" \
        "ip=192.168.50.101::192.168.50.1:255.255.255.0:iscsi-1:enp0s1:off" \
        "rd.iscsi.initiator=$initiator" \
        || return 1

    run_client "netroot=iscsi target1 target2" \
        "root=LABEL=sysroot" \
        "ip=dhcp" \
        "netroot=iscsi:192.168.51.1::::iqn.2009-06.dracut:target1" \
        "netroot=iscsi:192.168.50.1::::iqn.2009-06.dracut:target2" \
        "rd.iscsi.initiator=$initiator" \
        || return 1

    run_client "root=ibft" \
        "root=LABEL=singleroot" \
        "rd.iscsi.ibft=1" \
        "rd.iscsi.firmware=1" \
        || return 1

    echo "All tests passed [OK]"
    return 0
}

test_run() {
    if ! run_server; then
        echo "Failed to start server" 1>&2
        return 1
    fi
    do_test_run
    ret=$?
    if [[ -s $TESTDIR/server.pid ]]; then
        kill -TERM "$(cat "$TESTDIR"/server.pid)"
        rm -f -- "$TESTDIR"/server.pid
    fi
    return $ret
}

test_check() {
    if ! command -v tgtd &> /dev/null || ! command -v tgtadm &> /dev/null; then
        echo "Need tgtd and tgtadm from scsi-target-utils"
        return 1
    fi
}

test_setup() {
    # Create what will eventually be the client root filesystem onto an overlay
    "$DRACUT" -l --keep --tmpdir "$TESTDIR" \
        -m "test-root" \
        -i ./client-init.sh /sbin/init \
        -I "ip ping grep setsid" \
        -i "${PKGLIBDIR}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh" \
        -i "${PKGLIBDIR}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh" \
        --no-hostonly --no-hostonly-cmdline --nohardlink \
        -f "$TESTDIR"/initramfs.root "$KVERSION" || return 1
    mkdir -p "$TESTDIR"/overlay/source && mv "$TESTDIR"/dracut.*/initramfs/* "$TESTDIR"/overlay/source && rm -rf "$TESTDIR"/dracut.*

    mkdir -p -- "$TESTDIR"/overlay/source/var/lib/nfs/rpc_pipefs

    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -m "test-makeroot crypt lvm mdraid" \
        -I "mkfs.ext4 setsid blockdev" \
        -i ./create-client-root.sh /var/lib/dracut/hooks/initqueue/01-create-client-root.sh \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker 1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/singleroot.img singleroot 200
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid0-1.img raid0-1 100
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/raid0-2.img raid0-2 100

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/fakeroot rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    test_marker_check dracut-root-block-created || return 1
    rm -- "$TESTDIR"/marker.img

    # Create what will eventually be the server root filesystem onto an overlay
    "$DRACUT" -l --keep --tmpdir "$TESTDIR" \
        -m "test-root network network-legacy" \
        -d "iscsi_tcp crc32c ipv6" \
        -i ./server-init.sh /sbin/init \
        -i "${PKGLIBDIR}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh" \
        -i "${PKGLIBDIR}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh" \
        -I "modprobe chmod ip ping tcpdump setsid pidof tgtd tgtadm /etc/passwd" \
        --install-optional "/etc/netconfig dhcpd /etc/group /etc/nsswitch.conf /etc/rpc /etc/protocols /etc/services /usr/etc/nsswitch.conf /usr/etc/rpc /usr/etc/protocols /usr/etc/services" \
        -i "./hosts" "/etc/hosts" \
        -i "./dhcpd.conf" "/etc/dhcpd.conf" \
        --no-hostonly --no-hostonly-cmdline --nohardlink \
        -f "$TESTDIR"/initramfs.root "$KVERSION" || return 1
    mkdir -p "$TESTDIR"/overlay/source && mv "$TESTDIR"/dracut.*/initramfs/* "$TESTDIR"/overlay/source && rm -rf "$TESTDIR"/dracut.*

    mkdir -p "$TESTDIR"/overlay/source/var/lib/dhcpd

    # second, install the files needed to make the root filesystem
    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    "$DRACUT" -l -i "$TESTDIR"/overlay / \
        -m "test-makeroot" \
        -I "mkfs.ext4" \
        -i ./create-server-root.sh /var/lib/dracut/hooks/initqueue/01-create-server-root.sh \
        --nomdadmconf \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker 1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/server.img root 240

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/dracut/root rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1
    test_marker_check dracut-root-block-created || return 1
    rm -- "$TESTDIR"/marker.img

    # Make server's dracut image
    "$DRACUT" -l \
        -a "dash rootfs-block test kernel-modules network network-legacy" \
        -d "piix ide-gd_mod ata_piix ext4 sd_mod e1000 drbg" \
        -i "./server.link" "/etc/systemd/network/01-server.link" \
        -i ./wait-if-server.sh /var/lib/dracut/hooks/pre-mount/99-wait-if-server.sh \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.server "$KVERSION" || return 1

    # Make client's dracut image
    test_dracut \
        --add "$USE_NETWORK" \
        --include "./client.link" "/etc/systemd/network/01-client.link" \
        --kernel-cmdline "rw rd.auto rd.retry=50" \
        "$TESTDIR"/initramfs.testing
}

test_cleanup() {
    if [[ -s $TESTDIR/server.pid ]]; then
        kill -TERM "$(cat "$TESTDIR"/server.pid)"
        rm -f -- "$TESTDIR"/server.pid
    fi
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
