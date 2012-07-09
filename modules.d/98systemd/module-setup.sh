#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [[ $mount_needs ]] && return 1
    if [[ -x $systemdutildir/systemd ]]; then
       return 255
    fi

    return 1
}

depends() {
    return 0
}

install() {
    if strstr "$prefix" "/run/"; then
        dfatal "systemd does not work a prefix, which contains \"/run\"!!"
        exit 1
    fi

    dracut_install -o \
        $systemdutildir/systemd \
        $systemdutildir/systemd-cgroups-agent \
        $systemdutildir/systemd-initctl \
        $systemdutildir/systemd-shutdown \
        $systemdutildir/systemd-reply-password \
        $systemdutildir/systemd-fsck \
        $systemdutildir/systemd-udevd \
        $systemdutildir/systemd-journald \
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
        $systemdsystemunitdir/systemd-ask-password-console.path \
        $systemdsystemunitdir/systemd-udevd-control.socket \
        $systemdsystemunitdir/systemd-udevd-kernel.socket \
        $systemdsystemunitdir/systemd-ask-password-plymouth.path \
        $systemdsystemunitdir/systemd-journald.socket \
        $systemdsystemunitdir/systemd-initctl.service \
        $systemdsystemunitdir/systemd-shutdownd.service \
        $systemdsystemunitdir/systemd-ask-password-console.service \
        $systemdsystemunitdir/halt.service \
        $systemdsystemunitdir/poweroff.service \
        $systemdsystemunitdir/reboot.service \
        $systemdsystemunitdir/kexec.service \
        $systemdsystemunitdir/fsck@.service \
        $systemdsystemunitdir/systemd-udevd.service \
        $systemdsystemunitdir/systemd-udev-trigger.service \
        $systemdsystemunitdir/systemd-udev-settle.service \
        $systemdsystemunitdir/systemd-ask-password-plymouth.service \
        $systemdsystemunitdir/systemd-journald.service \
        $systemdsystemunitdir/systemd-vconsole-setup.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-modules-load.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-ask-password-console.path \
        $systemdsystemunitdir/sysinit.target.wants/systemd-vconsole-setup.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-journald.service \
        $systemdsystemunitdir/sockets.target.wants/systemd-initctl.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-shutdownd.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-udevd-control.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-udevd-kernel.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-journald.socket \
        $systemdsystemunitdir/sysinit.target.wants/systemd-udevd.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-udev-trigger.service \
        $systemdsystemunitdir/ctrl-alt-del.target \
        $systemdsystemunitdir/single.service \
        $systemdsystemunitdir/syslog.socket \
        $systemdsystemunitdir/syslog.target \
        $systemdsystemunitdir/initrd-switch-root.target \
        $systemdsystemunitdir/initrd-switch-root.service \
        $systemdsystemunitdir/umount.target \
        journalctl systemctl echo

    if [[ $hostonly ]]; then
        dracut_install -o /etc/systemd/journald.conf \
            /etc/systemd/system.conf \
            /etc/hostname \
            /etc/machine-id \
            /etc/vconsole.conf \
            /etc/locale.conf
    else
        if ! [[ -e "$initdir/etc/machine-id" ]]; then
            > "$initdir/etc/machine-id"
        fi
    fi

    # install adm user/group for journald
    dracut_install nologin
    egrep '^adm:' "$initdir/etc/passwd" 2>/dev/null >> "$initdir/etc/passwd"
    egrep '^adm:' /etc/group >> "$initdir/etc/group"

    ln -fs $systemdutildir/systemd "$initdir/init"

    rm -f "${initdir}${systemdsystemunitdir}/emergency.service"
    inst_simple "$moddir/emergency.service" ${systemdsystemunitdir}/emergency.service

    rm -f "${initdir}${systemdsystemunitdir}/rescue.service"
    inst_simple "$moddir/rescue.service" ${systemdsystemunitdir}/rescue.service

    inst_simple "$moddir/initrd-switch-root.target" ${systemdsystemunitdir}/initrd-switch-root.target
    inst_simple "$moddir/initrd-switch-root.service" ${systemdsystemunitdir}/initrd-switch-root.service
    ln -fs basic.target "${initdir}${systemdsystemunitdir}/default.target"

    mkdir -p "${initdir}${systemdsystemunitdir}/basic.target.wants"

    inst_script "$moddir/dracut-cmdline.sh" /bin/dracut-cmdline
    inst_simple "$moddir/dracut-cmdline.service" ${systemdsystemunitdir}/dracut-cmdline.service
    ln -fs ../dracut-cmdline.service "${initdir}${systemdsystemunitdir}/basic.target.wants/dracut-cmdline.service"

    inst_script "$moddir/dracut-pre-udev.sh" /bin/dracut-pre-udev
    inst_simple "$moddir/dracut-pre-udev.service" ${systemdsystemunitdir}/dracut-pre-udev.service
    ln -fs ../dracut-pre-udev.service "${initdir}${systemdsystemunitdir}/basic.target.wants/dracut-pre-udev.service"

    inst_script "$moddir/dracut-pre-trigger.sh" /bin/dracut-pre-trigger
    inst_simple "$moddir/dracut-pre-trigger.service" ${systemdsystemunitdir}/dracut-pre-trigger.service
    ln -fs ../dracut-pre-trigger.service "${initdir}${systemdsystemunitdir}/basic.target.wants/dracut-pre-trigger.service"

    inst_script "$moddir/dracut-initqueue.sh" /bin/dracut-initqueue
    inst_simple "$moddir/dracut-initqueue.service" ${systemdsystemunitdir}/dracut-initqueue.service
    ln -fs ../dracut-initqueue.service "${initdir}${systemdsystemunitdir}/basic.target.wants/dracut-initqueue.service"

    inst_script "$moddir/dracut-pre-pivot.sh" /bin/dracut-pre-pivot
    inst_simple "$moddir/dracut-pre-pivot.service" ${systemdsystemunitdir}/dracut-pre-pivot.service
    mkdir -p "${initdir}${systemdsystemunitdir}/initrd-switch-root.target.wants"
    ln -fs ../dracut-pre-pivot.service "${initdir}${systemdsystemunitdir}/initrd-switch-root.target.wants/dracut-pre-pivot.service"

}

