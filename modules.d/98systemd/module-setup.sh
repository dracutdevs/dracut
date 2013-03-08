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

    SYSTEMD_VERSION=$($systemdutildir/systemd --version | { read a b a; echo $b; })
    if (( $SYSTEMD_VERSION < 198 )); then
        dfatal "systemd version $SYSTEMD_VERSION is too low. Need at least version 198."
        exit 1
    fi

    if strstr "$prefix" "/run/"; then
        dfatal "systemd does not work a prefix, which contains \"/run\"!!"
        exit 1
    fi

    dracut_install -o \
        $systemdutildir/systemd \
        $systemdutildir/systemd-cgroups-agent \
        $systemdutildir/systemd-shutdown \
        $systemdutildir/systemd-reply-password \
        $systemdutildir/systemd-fsck \
        $systemdutildir/systemd-udevd \
        $systemdutildir/systemd-journald \
        $systemdutildir/systemd-sysctl \
        $systemdutildir/systemd-modules-load \
        $systemdutildir/system-generators/systemd-fstab-generator \
        $systemdsystemunitdir/cryptsetup.target \
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
        $systemdsystemunitdir/systemd-ask-password-console.path \
        $systemdsystemunitdir/systemd-udevd-control.socket \
        $systemdsystemunitdir/systemd-udevd-kernel.socket \
        $systemdsystemunitdir/systemd-ask-password-plymouth.path \
        $systemdsystemunitdir/systemd-journald.socket \
        $systemdsystemunitdir/systemd-ask-password-console.service \
        $systemdsystemunitdir/systemd-modules-load.service \
        $systemdsystemunitdir/halt.service \
        $systemdsystemunitdir/systemd-halt.service \
        $systemdsystemunitdir/poweroff.service \
        $systemdsystemunitdir/systemd-poweroff.service \
        $systemdsystemunitdir/systemd-reboot.service \
        $systemdsystemunitdir/kexec.service \
        $systemdsystemunitdir/systemd-kexec.service \
        $systemdsystemunitdir/fsck@.service \
        $systemdsystemunitdir/systemd-fsck@.service \
        $systemdsystemunitdir/systemd-udevd.service \
        $systemdsystemunitdir/systemd-udev-trigger.service \
        $systemdsystemunitdir/systemd-udev-settle.service \
        $systemdsystemunitdir/systemd-ask-password-plymouth.service \
        $systemdsystemunitdir/systemd-journald.service \
        $systemdsystemunitdir/systemd-vconsole-setup.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-modules-load.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-ask-password-console.path \
        $systemdsystemunitdir/sysinit.target.wants/systemd-journald.service \
        $systemdsystemunitdir/sockets.target.wants/systemd-udevd-control.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-udevd-kernel.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-journald.socket \
        $systemdsystemunitdir/sysinit.target.wants/systemd-udevd.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-udev-trigger.service \
\
        $systemdsystemunitdir/ctrl-alt-del.target \
        $systemdsystemunitdir/syslog.socket \
        $systemdsystemunitdir/syslog.target \
        $systemdsystemunitdir/initrd-switch-root.target \
        $systemdsystemunitdir/initrd-switch-root.service \
        $systemdsystemunitdir/initrd-cleanup.service \
        $systemdsystemunitdir/initrd-udevadm-cleanup-db.service \
        $systemdsystemunitdir/initrd-parse-etc.service \
\
        $systemdsystemunitdir/umount.target \
        journalctl systemctl echo swapoff systemd-cgls

    dracut_install -o \
        /usr/lib/modules-load.d/*.conf

    if [[ $hostonly ]]; then
        dracut_install -o \
            /etc/systemd/journald.conf \
            /etc/systemd/system.conf \
            /etc/hostname \
            /etc/machine-id \
            /etc/vconsole.conf \
            /etc/locale.conf

        dracut_install -o \
            /etc/modules-load.d/*.conf
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
    ln -fs $systemdutildir/systemd "$initdir/sbin/init"

    inst_script "$moddir/dracut-emergency.sh" /bin/dracut-emergency
    inst_simple "$moddir/emergency.service" ${systemdsystemunitdir}/emergency.service
    inst_simple "$moddir/dracut-emergency.service" ${systemdsystemunitdir}/dracut-emergency.service
    inst_simple "$moddir/emergency.service" ${systemdsystemunitdir}/rescue.service

    dracutsystemunitdir="/etc/systemd/system"

    mkdir -p "${initdir}${dracutsystemunitdir}/dracut.target.wants"

    mkdir -p "${initdir}${systemdsystemunitdir}/sysinit.target.d"
    {
        echo "[Unit]"
        echo "After="
        echo "After=emergency.service emergency.target"
    } > "${initdir}${systemdsystemunitdir}/sysinit.target.d/nolocalfs.conf"

    inst_simple "$moddir/dracut.target" ${dracutsystemunitdir}/dracut.target
    ln -fs ${dracutsystemunitdir}/dracut.target "${initdir}${systemdsystemunitdir}/default.target"

    inst_script "$moddir/dracut-cmdline.sh" /bin/dracut-cmdline
    inst_simple "$moddir/dracut-cmdline.service" ${dracutsystemunitdir}/dracut-cmdline.service
    ln -fs ../dracut-cmdline.service "${initdir}${dracutsystemunitdir}/dracut.target.wants/dracut-cmdline.service"

    inst_script "$moddir/dracut-pre-udev.sh" /bin/dracut-pre-udev
    inst_simple "$moddir/dracut-pre-udev.service" ${dracutsystemunitdir}/dracut-pre-udev.service
    ln -fs ../dracut-pre-udev.service "${initdir}${dracutsystemunitdir}/dracut.target.wants/dracut-pre-udev.service"

    inst_script "$moddir/dracut-pre-trigger.sh" /bin/dracut-pre-trigger
    inst_simple "$moddir/dracut-pre-trigger.service" ${dracutsystemunitdir}/dracut-pre-trigger.service
    ln -fs ../dracut-pre-trigger.service "${initdir}${dracutsystemunitdir}/dracut.target.wants/dracut-pre-trigger.service"

    inst_script "$moddir/dracut-initqueue.sh" /bin/dracut-initqueue
    inst_simple "$moddir/dracut-initqueue.service" ${dracutsystemunitdir}/dracut-initqueue.service
    ln -fs ../dracut-initqueue.service "${initdir}${dracutsystemunitdir}/dracut.target.wants/dracut-initqueue.service"

    inst_script "$moddir/dracut-pre-mount.sh" /bin/dracut-pre-mount
    inst_simple "$moddir/dracut-pre-mount.service" ${dracutsystemunitdir}/dracut-pre-mount.service
    ln -fs ../dracut-pre-mount.service "${initdir}${dracutsystemunitdir}/dracut.target.wants/dracut-pre-mount.service"

    inst_script "$moddir/dracut-mount.sh" /bin/dracut-mount
    inst_simple "$moddir/dracut-mount.service" ${dracutsystemunitdir}/dracut-mount.service
    ln -fs ../dracut-mount.service "${initdir}${dracutsystemunitdir}/dracut.target.wants/dracut-mount.service"

    inst_script "$moddir/dracut-pre-pivot.sh" /bin/dracut-pre-pivot
    inst_simple "$moddir/dracut-pre-pivot.service" ${dracutsystemunitdir}/dracut-pre-pivot.service
    ln -fs ../dracut-pre-pivot.service "${initdir}${dracutsystemunitdir}/dracut.target.wants/dracut-pre-pivot.service"

    ln -fs ../initrd-parse-etc.service "${initdir}${dracutsystemunitdir}/dracut.target.wants/initrd-parse-etc.service"

    inst_rules 99-systemd.rules

    for i in \
        emergency.target \
        dracut-emergency.service \
        rescue.service \
        systemd-ask-password-console.service \
        systemd-ask-password-plymouth.service \
        ; do
        mkdir -p "${initdir}${dracutsystemunitdir}/${i}.wants"
        ln_r "${systemdsystemunitdir}/systemd-vconsole-setup.service" \
            "${dracutsystemunitdir}/${i}.wants/systemd-vconsole-setup.service"
    done

    # turn off RateLimit for journal
    {
        echo "[Journal]"
        echo "RateLimitInterval=0"
        echo "RateLimitBurst=0"
    } >> "$initdir/etc/systemd/journald.conf"


}

