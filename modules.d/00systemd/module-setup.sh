#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {
    [[ $mount_needs ]] && return 1
    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries "$systemdutildir"/systemd || return 1
    # Return 255 to only include the module, if another module requires it.
    return 255
}

# called by dracut
depends() {
    return 0
}

installkernel() {
    hostonly='' instmods autofs4 ipv6 algif_hash hmac sha256
    instmods -s efivarfs
}

# called by dracut
install() {
    local _mods

    if [[ $prefix == /run/* ]]; then
        dfatal 'systemd does not work with a prefix, which contains "/run"!!'
        exit 1
    fi

    inst_multiple -o \
        "$systemdutildir"/systemd \
        "$systemdutildir"/systemd-coredump \
        "$systemdutildir"/systemd-cgroups-agent \
        "$systemdutildir"/systemd-executor \
        "$systemdutildir"/systemd-shutdown \
        "$systemdutildir"/systemd-reply-password \
        "$systemdutildir"/systemd-fsck \
        "$systemdutildir"/systemd-udevd \
        "$systemdutildir"/systemd-journald \
        "$systemdutildir"/systemd-sysctl \
        "$systemdutildir"/systemd-modules-load \
        "$systemdutildir"/systemd-vconsole-setup \
        "$systemdutildir"/systemd-volatile-root \
        "$systemdutildir"/systemd-sysroot-fstab-check \
        "$systemdutildir"/system-generators/systemd-debug-generator \
        "$systemdutildir"/system-generators/systemd-fstab-generator \
        "$systemdutildir"/system-generators/systemd-gpt-auto-generator \
        "$systemdsystemunitdir"/debug-shell.service \
        "$systemdsystemunitdir"/cryptsetup.target \
        "$systemdsystemunitdir"/cryptsetup-pre.target \
        "$systemdsystemunitdir"/remote-cryptsetup.target \
        "$systemdsystemunitdir"/emergency.target \
        "$systemdsystemunitdir"/sysinit.target \
        "$systemdsystemunitdir"/basic.target \
        "$systemdsystemunitdir"/halt.target \
        "$systemdsystemunitdir"/kexec.target \
        "$systemdsystemunitdir"/local-fs.target \
        "$systemdsystemunitdir"/local-fs-pre.target \
        "$systemdsystemunitdir"/remote-fs.target \
        "$systemdsystemunitdir"/remote-fs-pre.target \
        "$systemdsystemunitdir"/multi-user.target \
        "$systemdsystemunitdir"/network.target \
        "$systemdsystemunitdir"/network-pre.target \
        "$systemdsystemunitdir"/network-online.target \
        "$systemdsystemunitdir"/nss-lookup.target \
        "$systemdsystemunitdir"/nss-user-lookup.target \
        "$systemdsystemunitdir"/poweroff.target \
        "$systemdsystemunitdir"/reboot.target \
        "$systemdsystemunitdir"/rescue.target \
        "$systemdsystemunitdir"/rpcbind.target \
        "$systemdsystemunitdir"/shutdown.target \
        "$systemdsystemunitdir"/final.target \
        "$systemdsystemunitdir"/sigpwr.target \
        "$systemdsystemunitdir"/sockets.target \
        "$systemdsystemunitdir"/swap.target \
        "$systemdsystemunitdir"/timers.target \
        "$systemdsystemunitdir"/paths.target \
        "$systemdsystemunitdir"/umount.target \
        "$systemdsystemunitdir"/sys-kernel-config.mount \
        "$systemdsystemunitdir"/modprobe@.service \
        "$systemdsystemunitdir"/kmod-static-nodes.service \
        "$systemdsystemunitdir"/systemd-tmpfiles-setup.service \
        "$systemdsystemunitdir"/systemd-tmpfiles-setup-dev.service \
        "$systemdsystemunitdir"/systemd-tmpfiles-setup-dev-early.service \
        "$systemdsystemunitdir"/systemd-ask-password-console.path \
        "$systemdsystemunitdir"/systemd-udevd-control.socket \
        "$systemdsystemunitdir"/systemd-udevd-kernel.socket \
        "$systemdsystemunitdir"/systemd-ask-password-plymouth.path \
        "$systemdsystemunitdir"/systemd-journald.socket \
        "$systemdsystemunitdir"/systemd-journald-audit.socket \
        "$systemdsystemunitdir"/systemd-ask-password-console.service \
        "$systemdsystemunitdir"/systemd-modules-load.service \
        "$systemdsystemunitdir"/systemd-halt.service \
        "$systemdsystemunitdir"/systemd-poweroff.service \
        "$systemdsystemunitdir"/systemd-reboot.service \
        "$systemdsystemunitdir"/systemd-kexec.service \
        "$systemdsystemunitdir"/systemd-fsck@.service \
        "$systemdsystemunitdir"/systemd-udevd.service \
        "$systemdsystemunitdir"/systemd-udev-trigger.service \
        "$systemdsystemunitdir"/systemd-udev-settle.service \
        "$systemdsystemunitdir"/systemd-ask-password-plymouth.service \
        "$systemdsystemunitdir"/systemd-journald.service \
        "$systemdsystemunitdir"/systemd-vconsole-setup.service \
        "$systemdsystemunitdir"/systemd-volatile-root.service \
        "$systemdsystemunitdir"/systemd-sysctl.service \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-modules-load.service \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-ask-password-console.path \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-journald.service \
        "$systemdsystemunitdir"/sockets.target.wants/systemd-udevd-control.socket \
        "$systemdsystemunitdir"/sockets.target.wants/systemd-udevd-kernel.socket \
        "$systemdsystemunitdir"/sockets.target.wants/systemd-journald.socket \
        "$systemdsystemunitdir"/sockets.target.wants/systemd-journald-audit.socket \
        "$systemdsystemunitdir"/sockets.target.wants/systemd-journald-dev-log.socket \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-udevd.service \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-udev-trigger.service \
        "$systemdsystemunitdir"/sysinit.target.wants/kmod-static-nodes.service \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-tmpfiles-setup.service \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-tmpfiles-setup-dev.service \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-tmpfiles-setup-dev-early.service \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-sysctl.service \
        "$systemdsystemunitdir"/ctrl-alt-del.target \
        "$systemdsystemunitdir"/reboot.target \
        "$systemdsystemunitdir"/systemd-reboot.service \
        "$systemdsystemunitdir"/syslog.socket \
        "$systemdsystemunitdir"/slices.target \
        "$systemdsystemunitdir"/system.slice \
        "$systemdsystemunitdir"/-.slice \
        "$tmpfilesdir"/systemd.conf \
        journalctl systemctl \
        echo swapoff \
        kmod insmod rmmod modprobe modinfo depmod lsmod \
        mount umount reboot poweroff \
        systemd-run systemd-escape \
        systemd-cgls systemd-tmpfiles \
        systemd-ask-password systemd-tty-ask-password-agent \
        /etc/udev/udev.hwdb

    inst_multiple -o \
        /usr/lib/modules-load.d/*.conf \
        /usr/lib/sysctl.d/*.conf

    modules_load_get() {
        local _line i
        for i in "$dracutsysrootdir$1"/*.conf; do
            [[ -f $i ]] || continue
            while read -r _line || [ -n "$_line" ]; do
                case $_line in
                    \#*) ;;

                    \;*) ;;

                    *)
                        echo "$_line"
                        ;;
                esac
            done < "$i"
        done
    }

    mapfile -t _mods < <(modules_load_get /usr/lib/modules-load.d)
    [[ ${#_mods[@]} -gt 0 ]] && hostonly='' instmods "${_mods[@]}"

    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            /etc/systemd/journald.conf \
            /etc/systemd/journald.conf.d/*.conf \
            /etc/systemd/system.conf \
            /etc/systemd/system.conf.d/*.conf \
            "$systemdsystemconfdir"/modprobe@.service \
            "$systemdsystemconfdir/modprobe@.service.d/*.conf" \
            /etc/hosts \
            /etc/hostname \
            /etc/nsswitch.conf \
            /etc/machine-id \
            /etc/machine-info \
            /etc/vconsole.conf \
            /etc/locale.conf \
            /etc/modules-load.d/*.conf \
            /etc/sysctl.d/*.conf \
            /etc/sysctl.conf \
            /etc/udev/udev.conf

        mapfile -t _mods < <(modules_load_get /etc/modules-load.d)
        [[ ${#_mods[@]} -gt 0 ]] && hostonly='' instmods "${_mods[@]}"
    fi

    if ! [[ -e "$initdir/etc/machine-id" ]]; then
        : > "$initdir/etc/machine-id"
        chmod 444 "$initdir/etc/machine-id"
    fi

    # install adm user/group for journald
    inst_multiple nologin
    {
        grep '^systemd-journal:' "$dracutsysrootdir"/etc/passwd 2> /dev/null
        grep '^adm:' "$dracutsysrootdir"/etc/passwd 2> /dev/null
        # we don't use systemd-networkd, but the user is in systemd.conf tmpfiles snippet
        grep '^systemd-network:' "$dracutsysrootdir"/etc/passwd 2> /dev/null
    } >> "$initdir/etc/passwd"

    {
        grep '^systemd-journal:' "$dracutsysrootdir"/etc/group 2> /dev/null
        grep '^wheel:' "$dracutsysrootdir"/etc/group 2> /dev/null
        grep '^adm:' "$dracutsysrootdir"/etc/group 2> /dev/null
        grep '^utmp:' "$dracutsysrootdir"/etc/group 2> /dev/null
        grep '^root:' "$dracutsysrootdir"/etc/group 2> /dev/null
        # we don't use systemd-networkd, but the user is in systemd.conf tmpfiles snippet
        grep '^systemd-network:' "$dracutsysrootdir"/etc/group 2> /dev/null
    } >> "$initdir/etc/group"

    local _systemdbinary="$systemdutildir"/systemd

    if ldd "$_systemdbinary" | grep -qw libasan; then
        local _wrapper="$systemdutildir"/systemd-asan-wrapper
        cat > "$initdir"/"$_wrapper" << EOF
#!/bin/sh
mount -t proc -o nosuid,nodev,noexec proc /proc
exec $_systemdbinary
EOF
        chmod 755 "$initdir"/"$_wrapper"
        _systemdbinary="$_wrapper"
        unset _wrapper
    fi
    ln_r "$_systemdbinary" "/init"
    ln_r "$_systemdbinary" "/sbin/init"

    unset _systemdbinary

    inst_binary true
    ln_r "$(find_binary true)" "/usr/bin/loginctl"
    ln_r "$(find_binary true)" "/bin/loginctl"
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
        systemd-ask-password-plymouth.service; do
        [[ -f "$systemdsystemunitdir"/$i ]] || continue
        $SYSTEMCTL -q --root "$initdir" add-wants "$i" systemd-vconsole-setup.service
    done

    mkdir -p "$initdir/etc/systemd"
    # We must use a volatile journal, and we don't want rate-limiting
    {
        echo "[Journal]"
        echo "Storage=volatile"
        echo "RateLimitInterval=0"
        echo "RateLimitBurst=0"
    } >> "$initdir/etc/systemd/journald.conf"

    $SYSTEMCTL -q --root "$initdir" set-default multi-user.target

    # Install library file(s)
    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file \
        {"tls/$_arch/",tls/,"$_arch/",}"libgcrypt.so*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libkmod.so*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libnss_*"

}
