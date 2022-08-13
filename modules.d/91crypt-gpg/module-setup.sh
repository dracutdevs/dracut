#!/bin/sh

# GPG support is optional
# called by dracut
check() {
    require_binaries gpg tr || return 1

    if sc_requested; then
        if ! sc_supported; then
            dwarning "crypt-gpg: GnuPG >= 2.1 with scdaemon and libusb required for ccid smartcard support"
            return 1
        fi
        return 0
    fi

    return 255
}

# called by dracut
depends() {
    echo crypt
}

# called by dracut
install() {
    inst_multiple gpg tr
    inst "$moddir/crypt-gpg-lib.sh" "/lib/dracut-crypt-gpg-lib.sh"

    if sc_requested; then
        inst_multiple gpg-agent
        inst_multiple gpg-connect-agent
        inst_multiple -o /usr/libexec/scdaemon /usr/lib/gnupg/scdaemon
        cp "$dracutsysrootdir/etc/dracut.conf.d/crypt-public-key.gpg" "${initdir}/root/"
    fi
}

sc_requested() {
    [ -f "$dracutsysrootdir/etc/dracut.conf.d/crypt-public-key.gpg" ]
}

# CCID Smartcard support requires GnuPG >= 2.1 with scdaemon and libusb
sc_supported() {
    local gpgMajor
    local gpgMinor
    local scdaemon
    gpgMajor="$(gpg --version | sed -nr '1s|.* ([0-9]*).*|\1|p')"
    gpgMinor="$(gpg --version | sed -nr '1s|.* [0-9]*\.([0-9]*).*|\1|p')"

    if [ -x "$dracutsysrootdir"/usr/libexec/scdaemon ]; then
        scdaemon=/usr/libexec/scdaemon
    elif [ -x "$dracutsysrootdir"/usr/lib/gnupg/scdaemon ]; then
        scdaemon=/usr/lib/gnupg/scdaemon
    else
        return 1
    fi

    if { [ "${gpgMajor}" -gt 2 ] || { [ "${gpgMajor}" -eq 2 ] && [ "${gpgMinor}" -ge 1 ]; }; } \
        && require_binaries gpg-agent \
        && require_binaries gpg-connect-agent \
        && $DRACUT_LDD "${dracutsysrootdir}${scdaemon}" | grep -q libusb; then
        return 0
    else
        return 1
    fi
}
