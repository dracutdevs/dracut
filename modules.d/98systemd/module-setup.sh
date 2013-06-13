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
    local _mods

#    SYSTEMD_VERSION=$($systemdutildir/systemd --version | { read a b a; echo $b; })
#    if (( $SYSTEMD_VERSION < 198 )); then
#        dfatal "systemd version $SYSTEMD_VERSION is too low. Need at least version 198."
#        exit 1
#    fi

    if strstr "$prefix" "/run/"; then
        dfatal "systemd does not work with a prefix, which contains \"/run\"!!"
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
        $systemdsystemunitdir/initrd.target \
        $systemdsystemunitdir/initrd-fs.target \
        $systemdsystemunitdir/initrd-root-fs.target \
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
        $systemdsystemunitdir/timers.target \
        $systemdsystemunitdir/paths.target \
        $systemdsystemunitdir/systemd-ask-password-console.path \
        $systemdsystemunitdir/systemd-udevd-control.socket \
        $systemdsystemunitdir/systemd-udevd-kernel.socket \
        $systemdsystemunitdir/systemd-ask-password-plymouth.path \
        $systemdsystemunitdir/systemd-journald.socket \
        $systemdsystemunitdir/systemd-ask-password-console.service \
        $systemdsystemunitdir/systemd-modules-load.service \
        $systemdsystemunitdir/systemd-halt.service \
        $systemdsystemunitdir/systemd-poweroff.service \
        $systemdsystemunitdir/systemd-reboot.service \
        $systemdsystemunitdir/systemd-kexec.service \
        $systemdsystemunitdir/systemd-fsck@.service \
        $systemdsystemunitdir/systemd-udevd.service \
        $systemdsystemunitdir/systemd-udev-trigger.service \
        $systemdsystemunitdir/systemd-udev-settle.service \
        $systemdsystemunitdir/systemd-ask-password-plymouth.service \
        $systemdsystemunitdir/systemd-journald.service \
        $systemdsystemunitdir/systemd-vconsole-setup.service \
        $systemdsystemunitdir/systemd-random-seed-load.service \
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
        $systemdsystemunitdir/initrd-switch-root.target \
        $systemdsystemunitdir/initrd-switch-root.service \
        $systemdsystemunitdir/initrd-cleanup.service \
        $systemdsystemunitdir/initrd-udevadm-cleanup-db.service \
        $systemdsystemunitdir/initrd-parse-etc.service \
        \
        $systemdsystemunitdir/umount.target \
        journalctl systemctl echo swapoff systemd-cgls

    dracut_install -o \
        /usr/lib/modules-load.d/*.conf \
        /usr/lib/sysctl.d/*.conf

    modules_load_get() {
        local _line i
        for i in "$1"/*.conf; do
            [[ -f $i ]] || continue
            while read _line; do
                case $_line in
                    \#*)
                        ;;
                    \;*)
                        ;;
                    *)
                        echo $_line
                esac
            done < "$i"
        done
    }

    _mods=$(modules_load_get /usr/lib/modules-load.d)
    [[ $_mods ]] && instmods $_mods

    if [[ $hostonly ]]; then
        dracut_install -o \
            /etc/systemd/journald.conf \
            /etc/systemd/system.conf \
            /etc/hostname \
            /etc/machine-id \
            /etc/vconsole.conf \
            /etc/locale.conf \
            /etc/modules-load.d/*.conf \
            /etc/sysctl.d/*.conf \
            /etc/sysctl.conf

        _mods=$(modules_load_get /etc/modules-load.d)
        [[ $_mods ]] && instmods $_mods
    else
        if ! [[ -e "$initdir/etc/machine-id" ]]; then
            > "$initdir/etc/machine-id"
        fi
    fi

    # install adm user/group for journald
    dracut_install nologin
    egrep '^systemd-journal:' "$initdir/etc/passwd" 2>/dev/null >> "$initdir/etc/passwd"
    egrep '^systemd-journal:' /etc/group >> "$initdir/etc/group"

    ln -fs $systemdutildir/systemd "$initdir/init"
    ln -fs $systemdutildir/systemd "$initdir/sbin/init"

    inst_script "$moddir/dracut-emergency.sh" /bin/dracut-emergency
    inst_simple "$moddir/emergency.service" ${systemdsystemunitdir}/emergency.service
    inst_simple "$moddir/dracut-emergency.service" ${systemdsystemunitdir}/dracut-emergency.service
    inst_simple "$moddir/emergency.service" ${systemdsystemunitdir}/rescue.service

    ln -fs initrd.target "${initdir}${systemdsystemunitdir}/default.target"

    inst_script "$moddir/dracut-cmdline.sh" /bin/dracut-cmdline
    inst_script "$moddir/dracut-pre-udev.sh" /bin/dracut-pre-udev
    inst_script "$moddir/dracut-pre-trigger.sh" /bin/dracut-pre-trigger
    inst_script "$moddir/dracut-initqueue.sh" /bin/dracut-initqueue
    inst_script "$moddir/dracut-pre-mount.sh" /bin/dracut-pre-mount
    inst_script "$moddir/dracut-mount.sh" /bin/dracut-mount
    inst_script "$moddir/dracut-pre-pivot.sh" /bin/dracut-pre-pivot

    inst_rules 99-systemd.rules

    for i in \
        emergency.target \
        dracut-emergency.service \
        rescue.service \
        systemd-ask-password-console.service \
        systemd-ask-password-plymouth.service \
        ; do
        mkdir -p "${initdir}${systemdsystemunitdir}/${i}.wants"
        ln_r "${systemdsystemunitdir}/systemd-vconsole-setup.service" \
            "${systemdsystemunitdir}/${i}.wants/systemd-vconsole-setup.service"
    done

    mkdir -p "${initdir}/$systemdsystemunitdir/initrd.target.wants"
    for i in \
        dracut-cmdline.service \
        dracut-initqueue.service \
        dracut-mount.service \
        dracut-pre-mount.service \
        dracut-pre-pivot.service \
        dracut-pre-trigger.service \
        dracut-pre-udev.service \
        ; do
        inst_simple "$moddir/${i}" "$systemdsystemunitdir/${i}"
        ln_r "$systemdsystemunitdir/${i}" "$systemdsystemunitdir/initrd.target.wants/${i}"
    done

    mkdir -p "$initdir/etc/systemd"
    # turn off RateLimit for journal
    {
        echo "[Journal]"
        echo "RateLimitInterval=0"
        echo "RateLimitBurst=0"
    } >> "$initdir/etc/systemd/journald.conf"

}

