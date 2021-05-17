#!/bin/bash
# shellcheck disable=SC2034
TEST_DESCRIPTION="root filesystem on a LiveCD dmsquash filesystem"

KVERSION="${KVERSION-$(uname -r)}"

# Uncomment this to debug failures
#DEBUGFAIL="rd.shell rd.break rd.debug systemd.log_level=debug systemd.log_target=console"

test_check() {
    for pdir in $(python3 -c "import site; print(site.getsitepackages())" | sed -e 's/\[\(.*\)\]/\1/' -e "s/', /' /g"); do
        # shellcheck disable=SC2001
        pdir1=$(echo "$pdir" | sed "s/^'\(.*\)'$/\1/")
        if [[ -d $pdir1/imgcreate ]]; then
            return 0
        fi
    done
    echo "python-imgcreate not installed"
    return 1
}

test_run() {
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/livecd.iso livecd 1

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -boot order=d \
        -append "panic=1 oops=panic softlockup_panic=1 systemd.crash_reboot root=live:CDLABEL=LiveCD live rw quiet rd.retry=3 rd.info console=ttyS0,115200n81 selinux=0 rd.shell=0 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing

    # mediacheck test with qemu GUI
    # "$testdir"/run-qemu \
    #     -drive format=raw,bps=1000000,index=0,media=disk,file="$TESTDIR"/livecd.iso \
    #     -drive format=raw,index=1,media=disk,file="$TESTDIR"/root.img \
    #     -m 512M  -smp 2 \
    #     -net none \
    #     -append "root=live:CDLABEL=LiveCD live quiet rhgb selinux=0 rd.live.check" \
    #     -initrd "$TESTDIR"/initramfs.testing

    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1
}

test_setup() {
    mkdir -p -- "$TESTDIR"/overlay
    (
        # shellcheck disable=SC2030
        export initdir="$TESTDIR"/overlay
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        inst_multiple poweroff shutdown
        inst_hook shutdown-emergency 000 ./hard-off.sh
        inst_hook emergency 000 ./hard-off.sh
    )

    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        -a "debug dmsquash-live qemu" \
        -o "rngd" \
        -d "piix ide-gd_mod ata_piix ext3 sd_mod" \
        --no-hostonly-cmdline -N \
        -f "$TESTDIR"/initramfs.testing "$KVERSION" || return 1

    mkdir -p -- "$TESTDIR"/root-source
    kernel="$KVERSION"
    # Create what will eventually be our root filesystem onto an overlay
    (
        # shellcheck disable=SC2031
        export initdir="$TESTDIR"/root-source
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        (
            cd "$initdir" || exit
            mkdir -p -- dev sys proc etc var/run tmp
            mkdir -p root usr/bin usr/lib usr/lib64 usr/sbin
        )
        inst_multiple sh df free ls shutdown poweroff stty cat ps ln ip \
            mount dmesg dhclient mkdir cp ping dhclient \
            umount strace less dd sync
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [[ -f ${_terminfodir}/l/linux ]] && break
        done
        inst_multiple -o "${_terminfodir}"/l/linux
        inst "$basedir/modules.d/35network-legacy/dhclient-script.sh" "/sbin/dhclient-script"
        inst "$basedir/modules.d/35network-legacy/ifup.sh" "/sbin/ifup"

        inst_simple "${basedir}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh"
        inst_simple "${basedir}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh"
        inst_binary "${basedir}/dracut-util" "/usr/bin/dracut-util"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getarg"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getargs"

        inst_multiple grep syslinux isohybrid
        for f in /usr/share/syslinux/*; do
            inst_simple "$f"
        done
        inst_simple /etc/os-release
        inst ./test-init.sh /sbin/init
        inst "$TESTDIR"/initramfs.testing "/boot/initramfs-$KVERSION.img"
        [[ -f /etc/machine-id ]] && read -r MACHINE_ID < /etc/machine-id

        VMLINUZ="/lib/modules/${KVERSION}/vmlinuz"
        if ! [[ -e $VMLINUZ ]]; then
            if [[ $MACHINE_ID ]] && { [[ -d /boot/${MACHINE_ID} ]] || [[ -L /boot/${MACHINE_ID} ]]; }; then
                VMLINUZ="/boot/${MACHINE_ID}/$KVERSION/linux"
            fi
        fi
        [[ -e $VMLINUZ ]] || VMLINUZ="/boot/vmlinuz-${KVERSION}"

        inst "$VMLINUZ" "/boot/vmlinuz-${KVERSION}"
        find_binary plymouth > /dev/null && inst_multiple plymouth
        cp -a -- /etc/ld.so.conf* "$initdir"/etc
        ldconfig -r "$initdir"
    )
    python3 create.py -d -c livecd-fedora-minimal.ks
    return 0
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
