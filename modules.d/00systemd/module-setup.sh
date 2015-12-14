#!/bin/bash

# called by dracut
check() {
    [[ $mount_needs ]] && return 1
    if require_binaries $systemdutildir/systemd; then
        SYSTEMD_VERSION=$($systemdutildir/systemd --version | { read a b a; echo $b; })
        (( $SYSTEMD_VERSION >= 198 )) && return 0
       return 255
    fi

    return 1
}

# called by dracut
depends() {
    return 0
}

installkernel() {
    hostonly='' instmods autofs4 ipv6
    instmods -s efivarfs
}

# called by dracut
install() {
    local _mods

    if [[ "$prefix" == /run/* ]]; then
        dfatal "systemd does not work with a prefix, which contains \"/run\"!!"
        exit 1
    fi

    inst_multiple -o \
        $systemdutildir/systemd \
        $systemdutildir/systemd-cgroups-agent \
        $systemdutildir/systemd-shutdown \
        $systemdutildir/systemd-reply-password \
        $systemdutildir/systemd-fsck \
        $systemdutildir/systemd-udevd \
        $systemdutildir/systemd-journald \
        $systemdutildir/systemd-sysctl \
        $systemdutildir/systemd-modules-load \
        $systemdutildir/systemd-vconsole-setup \
        $systemdutildir/system-generators/systemd-fstab-generator \
        $systemdutildir/system-generators/systemd-gpt-auto-generator \
        \
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
        $systemdsystemunitdir/multi-user.target \
        $systemdsystemunitdir/network.target \
        $systemdsystemunitdir/network-pre.target \
        $systemdsystemunitdir/network-online.target \
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
        $systemdsystemunitdir/umount.target \
        \
        $systemdsystemunitdir/sys-kernel-config.mount \
        \
        $systemdsystemunitdir/kmod-static-nodes.service \
        $systemdsystemunitdir/systemd-tmpfiles-setup-dev.service \
        $systemdsystemunitdir/systemd-ask-password-console.path \
        $systemdsystemunitdir/systemd-udevd-control.socket \
        $systemdsystemunitdir/systemd-udevd-kernel.socket \
        $systemdsystemunitdir/systemd-ask-password-plymouth.path \
        $systemdsystemunitdir/systemd-journald.socket \
        $systemdsystemunitdir/systemd-journald-audit.socket \
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
        $systemdsystemunitdir/systemd-random-seed.service \
        $systemdsystemunitdir/systemd-sysctl.service \
        \
        $systemdsystemunitdir/sysinit.target.wants/systemd-modules-load.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-ask-password-console.path \
        $systemdsystemunitdir/sysinit.target.wants/systemd-journald.service \
        $systemdsystemunitdir/sockets.target.wants/systemd-udevd-control.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-udevd-kernel.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-journald.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-journald-audit.socket \
        $systemdsystemunitdir/sockets.target.wants/systemd-journald-dev-log.socket \
        $systemdsystemunitdir/sysinit.target.wants/systemd-udevd.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-udev-trigger.service \
        $systemdsystemunitdir/sysinit.target.wants/kmod-static-nodes.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-tmpfiles-setup-dev.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-sysctl.service \
        \
        $systemdsystemunitdir/ctrl-alt-del.target \
        $systemdsystemunitdir/reboot.target \
        $systemdsystemunitdir/systemd-reboot.service \
        $systemdsystemunitdir/syslog.socket \
        \
        $systemdsystemunitdir/slices.target \
        $systemdsystemunitdir/system.slice \
        \
        $tmpfilesdir/systemd.conf \
        \
        journalctl systemctl \
        echo swapoff \
        kmod insmod rmmod modprobe modinfo depmod lsmod \
        mount umount reboot poweroff \
        systemd-run systemd-escape \
        systemd-cgls systemd-tmpfiles

    inst_multiple -o \
        /usr/lib/modules-load.d/*.conf \
        /usr/lib/sysctl.d/*.conf

    modules_load_get() {
        local _line i
        for i in "$1"/*.conf; do
            [[ -f $i ]] || continue
            while read _line || [ -n "$_line" ]; do
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
        inst_multiple -H -o \
            /etc/systemd/journald.conf \
            /etc/systemd/system.conf \
            /etc/hostname \
            /etc/machine-id \
            /etc/machine-info \
            /etc/vconsole.conf \
            /etc/locale.conf \
            /etc/modules-load.d/*.conf \
            /etc/sysctl.d/*.conf \
            /etc/sysctl.conf

        _mods=$(modules_load_get /etc/modules-load.d)
        [[ $_mods ]] && instmods $_mods
    fi

    if ! [[ -e "$initdir/etc/machine-id" ]]; then
        > "$initdir/etc/machine-id"
    fi

    # install adm user/group for journald
    inst_multiple nologin
    egrep '^systemd-journal:' /etc/passwd 2>/dev/null >> "$initdir/etc/passwd"
    egrep '^adm:' /etc/passwd 2>/dev/null >> "$initdir/etc/passwd"
    egrep '^systemd-journal:' /etc/group >> "$initdir/etc/group"
    egrep '^wheel:' /etc/group >> "$initdir/etc/group"
    egrep '^adm:' /etc/group >> "$initdir/etc/group"

    ln_r $systemdutildir/systemd "/init"
    ln_r $systemdutildir/systemd "/sbin/init"

    inst_binary true
    ln_r $(type -P true) "/usr/bin/loginctl"
    ln_r $(type -P true) "/bin/loginctl"
    inst_rules \
        70-uaccess.rules \
        71-seat.rules \
        73-seat-late.rules \
        90-vconsole.rules \
        99-systemd.rules

    for i in \
        emergency.target \
        rescue.target \
        systemd-ask-password-console.service \
        systemd-ask-password-plymouth.service \
        ; do
        mkdir -p "${initdir}${systemdsystemunitdir}/${i}.wants"
        ln_r "${systemdsystemunitdir}/systemd-vconsole-setup.service" \
            "${systemdsystemunitdir}/${i}.wants/systemd-vconsole-setup.service"
    done

    mkdir -p "$initdir/etc/systemd"
    # turn off RateLimit for journal
    {
        echo "[Journal]"
        echo "RateLimitInterval=0"
        echo "RateLimitBurst=0"
    } >> "$initdir/etc/systemd/journald.conf"

    ln_r "${systemdsystemunitdir}/multi-user.target" "${systemdsystemunitdir}/default.target"
}

