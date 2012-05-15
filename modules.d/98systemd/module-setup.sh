#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [[ $mount_needs ]] && return 1
    [ -x /lib/systemd/systemd ] && return 255
    return 1
}

depends() {
    return 0
}

install() {

    for i in \
    systemd \
    systemd-cgroups-agent \
    systemd-initctl \
    systemd-shutdownd \
    systemd-shutdown \
    systemd-modules-load \
    systemd-remount-fs \
    systemd-reply-password \
    systemd-fsck \
    systemd-timestamp \
    systemd-ac-power \
    systemd-sysctl \
    systemd-udevd \
    systemd-journald \
    systemd-coredump \
    systemd-vconsole-setup \
    systemd-cryptsetup \
    systemd-localed \
    system/emergency.target \
    system/sysinit.target \
    system/basic.target \
    system/halt.target \
    system/kexec.target \
    system/local-fs.target \
    system/local-fs-pre.target \
    system/remote-fs.target \
    system/remote-fs-pre.target \
    system/network.target \
    system/nss-lookup.target \
    system/nss-user-lookup.target \
    system/poweroff.target \
    system/reboot.target \
    system/rescue.target \
    system/rpcbind.target \
    system/shutdown.target \
    system/final.target \
    system/sigpwr.target \
    system/sockets.target \
    system/swap.target \
    system/systemd-initctl.socket \
    system/systemd-shutdownd.socket \
    system/bluetooth.target \
    system/systemd-ask-password-console.path \
    system/systemd-udev-control.socket \
    system/systemd-udev-kernel.socket \
    system/systemd-ask-password-plymouth.path \
    system/systemd-journald.socket \
    system/cryptsetup.target \
    system/console-shell.service \
    system/console-getty.service \
    system/systemd-initctl.service \
    system/systemd-shutdownd.service \
    system/systemd-modules-load.service \
    system/systemd-remount-fs.service \
    system/systemd-ask-password-console.service \
    system/halt.service \
    system/poweroff.service \
    system/reboot.service \
    system/kexec.service \
    system/fsck@.service \
    system/systemd-udev.service \
    system/systemd-udev-trigger.service \
    system/systemd-udev-settle.service \
    system/systemd-ask-password-plymouth.service \
    system/systemd-journald.service \
    system/systemd-vconsole-setup.service \
    system/systemd-localed.service \
    system/sysinit.target.wants/systemd-modules-load.service \
    system/sysinit.target.wants/systemd-ask-password-console.path \
    system/sysinit.target.wants/systemd-journald.service \
    system/sysinit.target.wants/systemd-vconsole-setup.service \
    system/sysinit.target.wants/cryptsetup.target \
    system/sockets.target.wants/systemd-initctl.socket \
    system/sockets.target.wants/systemd-shutdownd.socket \
    system/sockets.target.wants/systemd-udev-control.socket \
    system/sockets.target.wants/systemd-udev-kernel.socket \
    system/sockets.target.wants/systemd-journald.socket \
    system/basic.target.wants/systemd-udev.service \
    system/basic.target.wants/systemd-udev-trigger.service \
    system/local-fs.target.wants/systemd-remount-fs.service \
    system/local-fs.target.wants/fsck-root.service \
    system/local-fs.target.wants/tmp.mount \
    system/ctrl-alt-del.target \
    system/autovt@.service \
    system/single.service \
    system/syslog.socket \
    system/syslog.target \
    system/switch-root.target \
    system/switch-root.service \
    system/umount.target \
    ;do
        [ -e "/lib/systemd/$i" ] && dracut_install "/lib/systemd/$i"
    done
    for i in /etc/systemd/*.conf; do 
        dracut_install "$i"
    done

    ln -fs /lib/systemd/systemd "$initdir/init"

#    {
#        echo "LogLevel=debug"
#        echo "LogTarget=console"
#    } >> "$initdir/etc/systemd/system.conf"

    rm -f "$initdir/lib/systemd/system/emergency.service"
    inst "$moddir/emergency.service" /lib/systemd/system/emergency.service
    rm -f "$initdir/lib/systemd/system/rescue.service"
    inst "$moddir/rescue.service" /lib/systemd/system/rescue.service
    inst "$moddir/switch-root.target" /lib/systemd/system/switch-root.target
    inst "$moddir/switch-root.service" /lib/systemd/system/switch-root.service
    ln -s basic.target "$initdir/lib/systemd/system/default.target"

    inst "$moddir/dracut-cmdline.sh" /lib/systemd/system-generators/dracut-cmdline.sh

    inst "$moddir/dracut-pre-udev.sh" /bin/dracut-pre-udev
    inst "$moddir/dracut-pre-udev.service" /lib/systemd/system/dracut-pre-udev.service
    ln -s ../dracut-pre-udev.service "$initdir/lib/systemd/system/basic.target.wants/dracut-pre-udev.service"

    inst "$moddir/dracut-pre-trigger.sh" /bin/dracut-pre-trigger
    inst "$moddir/dracut-pre-trigger.service" /lib/systemd/system/dracut-pre-trigger.service
    ln -s ../dracut-pre-trigger.service "$initdir/lib/systemd/system/basic.target.wants/dracut-pre-trigger.service"

    inst "$moddir/dracut-initqueue.sh" /bin/dracut-initqueue
    inst "$moddir/dracut-initqueue.service" /lib/systemd/system/dracut-initqueue.service
    ln -s ../dracut-initqueue.service "$initdir/lib/systemd/system/basic.target.wants/dracut-initqueue.service"
    
    inst "$moddir/dracut-pre-pivot.sh" /bin/dracut-pre-pivot
    inst "$moddir/dracut-pre-pivot.service" /lib/systemd/system/dracut-pre-pivot.service
    mkdir -p "$initdir/lib/systemd/system/switch-root.target.wants"
    ln -s ../dracut-pre-pivot.service "$initdir/lib/systemd/system/switch-root.target.wants/dracut-pre-pivot.service"
    > "$initdir/etc/machine-id" 
}

