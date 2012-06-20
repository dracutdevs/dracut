#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [[ $mount_needs ]] && return 1
    if [[ -x /lib/systemd/systemd ]] || [[ -x /usr/lib/systemd/systemd ]]; then
        return 255
    fi
    pkg-config systemd --variable=systemdutildir >/dev/null && return 255
    return 1
}

depends() {
    return 0
}

install() {
    dracut_install -o "$i" \
        $systemdutildir/systemd \
        $systemdutildir/systemd-cgroups-agent \
        $systemdutildir/systemd-initctl \
        $systemdutildir/systemd-shutdown \
        $systemdutildir/systemd-modules-load \
        $systemdutildir/systemd-remount-fs \
        $systemdutildir/systemd-reply-password \
        $systemdutildir/systemd-fsck \
        $systemdutildir/systemd-sysctl \
        $systemdutildir/systemd-udevd \
        $systemdutildir/systemd-journald \
        $systemdutildir/systemd-vconsole-setup \
        $systemdutildir/systemd-cryptsetup \
        $systemdsystemunitdir/emergency.target \
        $systemdsystemunitdir/sysinit.target \
        $systemdsystemunitdir/basic.target \
        $systemdsystemunitdir/halt.target \
        $systemdsystemunitdir/kexec.target \
        $systemdsystemunitdir/local-fs.target \
        $systemdsystemunitdir/local-fs-pre.target \
        $systemdsystemunitdir/remote-fs.target \
        $systemdsystemunitdir/remote-fs-pre.target \
        $systemdsystemunitdir/network.target \
        $systemdsystemunitdir/nss-lookup.target \
        $systemdsystemunitdir/nss-user-lookup.target \
        $systemdsystemunitdir/poweroff.target \
        $systemdsystemunitdir/reboot.target \
        $systemdsystemunitdir/rescue.target \
        $systemdsystemunitdir/rpcbind.target \
        $systemdsystemunitdir/shutdown.target \
        $systemdsystemunitdir/final.target \
        $systemdsystemunitdir/sigpwr.target \
        $systemdsystemunitdir/sockets.target \
        $systemdsystemunitdir/swap.target \
        $systemdsystemunitdir/systemd-initctl.socket \
        $systemdsystemunitdir/systemd-shutdownd.socket \
        $systemdsystemunitdir/bluetooth.target \
        $systemdsystemunitdir/systemd-ask-password-console.path \
        $systemdsystemunitdir/systemd-udev-control.socket \
        $systemdsystemunitdir/systemd-udev-kernel.socket \
        $systemdsystemunitdir/systemd-ask-password-plymouth.path \
        $systemdsystemunitdir/systemd-journald.socket \
        $systemdsystemunitdir/cryptsetup.target \
        $systemdsystemunitdir/console-shell.service \
        $systemdsystemunitdir/console-getty.service \
        $systemdsystemunitdir/systemd-initctl.service \
        $systemdsystemunitdir/systemd-shutdownd.service \
        $systemdsystemunitdir/systemd-modules-load.service \
        $systemdsystemunitdir/systemd-remount-fs.service \
        $systemdsystemunitdir/systemd-ask-password-console.service \
        $systemdsystemunitdir/halt.service \
        $systemdsystemunitdir/poweroff.service \
        $systemdsystemunitdir/reboot.service \
        $systemdsystemunitdir/kexec.service \
        $systemdsystemunitdir/fsck@.service \
        $systemdsystemunitdir/systemd-udev.service \
        $systemdsystemunitdir/systemd-udev-trigger.service \
        $systemdsystemunitdir/systemd-udev-settle.service \
        $systemdsystemunitdir/systemd-ask-password-plymouth.service \
        $systemdsystemunitdir/systemd-journald.service \
        $systemdsystemunitdir/systemd-vconsole-setup.service \
        $systemdsystemunitdir/systemd-localed.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-modules-load.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-ask-password-console.path \
        $systemdsystemunitdir/sysinit.target.wants/systemd-journald.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-vconsole-setup.service \
        $systemdsystemunitdir/sysinit.target.wants/cryptsetup.target \
        $systemdsystemunitdir/sockets.target.wants/systemd-initctl.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-shutdownd.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-udev-control.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-udev-kernel.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-journald.socket \
        $systemdsystemunitdir/sysinit.target.wants/systemd-udev.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-udev-trigger.service \
        $systemdsystemunitdir/local-fs.target.wants/systemd-remount-fs.service \
        $systemdsystemunitdir/local-fs.target.wants/fsck-root.service \
        $systemdsystemunitdir/local-fs.target.wants/tmp.mount \
        $systemdsystemunitdir/ctrl-alt-del.target \
        $systemdsystemunitdir/autovt@.service \
        $systemdsystemunitdir/single.service \
        $systemdsystemunitdir/syslog.socket \
        $systemdsystemunitdir/syslog.target \
        $systemdsystemunitdir/initrd-switch-root.target \
        $systemdsystemunitdir/initrd-switch-root.service \
        $systemdsystemunitdir/umount.target \
        $systemdsystemunitdir/udev-control.socket \
        $systemdsystemunitdir/udev-kernel.socket \
        $systemdsystemunitdir/udev.service \
        $systemdsystemunitdir/udev-settle.service \
        $systemdsystemunitdir/udev-trigger.service \
        $systemdsystemunitdir/basic.target.wants/udev.service \
        $systemdsystemunitdir/basic.target.wants/udev-trigger.service \
        $systemdsystemunitdir/sockets.target.wants/udev-control.socket \
        $systemdsystemunitdir/sockets.target.wants/udev-kernel.socket

    for i in /etc/systemd/*.conf; do
        dracut_install "$i"
    done

    dracut_install journalctl systemctl echo

    ln -fs $systemdutildir/systemd "$initdir/init"

    rm -f "${initdir}${systemdsystemunitdir}/emergency.service"
    inst "$moddir/emergency.service" ${systemdsystemunitdir}/emergency.service

    rm -f "${initdir}${systemdsystemunitdir}/rescue.service"
    inst "$moddir/rescue.service" ${systemdsystemunitdir}/rescue.service

    inst "$moddir/initrd-switch-root.target" ${systemdsystemunitdir}/initrd-switch-root.target
    inst "$moddir/initrd-switch-root.service" ${systemdsystemunitdir}/initrd-switch-root.service
    ln -s basic.target "${initdir}${systemdsystemunitdir}/default.target"

    inst "$moddir/dracut-cmdline.sh" ${systemdsystemunitdir}-generators/dracut-cmdline.sh

    mkdir -p "${initdir}${systemdsystemunitdir}/basic.target.wants"
    inst "$moddir/dracut-pre-udev.sh" /bin/dracut-pre-udev
    inst "$moddir/dracut-pre-udev.service" ${systemdsystemunitdir}/dracut-pre-udev.service
    ln -s ../dracut-pre-udev.service "${initdir}${systemdsystemunitdir}/basic.target.wants/dracut-pre-udev.service"

    inst "$moddir/dracut-pre-trigger.sh" /bin/dracut-pre-trigger
    inst "$moddir/dracut-pre-trigger.service" ${systemdsystemunitdir}/dracut-pre-trigger.service
    ln -s ../dracut-pre-trigger.service "${initdir}${systemdsystemunitdir}/basic.target.wants/dracut-pre-trigger.service"

    inst "$moddir/dracut-initqueue.sh" /bin/dracut-initqueue
    inst "$moddir/dracut-initqueue.service" ${systemdsystemunitdir}/dracut-initqueue.service
    ln -s ../dracut-initqueue.service "${initdir}${systemdsystemunitdir}/basic.target.wants/dracut-initqueue.service"

    inst "$moddir/dracut-pre-pivot.sh" /bin/dracut-pre-pivot
    inst "$moddir/dracut-pre-pivot.service" ${systemdsystemunitdir}/dracut-pre-pivot.service
    mkdir -p "${initdir}${systemdsystemunitdir}/initrd-switch-root.target.wants"
    ln -s ../dracut-pre-pivot.service "${initdir}${systemdsystemunitdir}/initrd-switch-root.target.wants/dracut-pre-pivot.service"

    > "$initdir/etc/machine-id"
}

