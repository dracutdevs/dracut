#!/bin/bash

# GPG support is optional
# called by dracut
check() {
    require_binaries gpg || return 1

    if [ -f "${initdir}/root/crypt-public-key.gpg" ]; then
        require_binaries gpg-agent || return 1
        require_binaries gpg-connect-agent || return 1
        require_binaries /usr/libexec/scdaemon || return 1
    fi

    return 255
}

# called by dracut
depends() {
    echo crypt
}

# called by dracut
install() {
    inst_multiple gpg
    inst "$moddir/crypt-gpg-lib.sh" "/lib/dracut-crypt-gpg-lib.sh"

    local gpgMajorVersion="$(gpg --version | sed -n 1p | sed -n -r -e 's|.* ([0-9]*).*|\1|p')"
    local gpgMinorVersion="$(gpg --version | sed -n 1p | sed -n -r -e 's|.* [0-9]*\.([0-9]*).*|\1|p')"
    if [ "${gpgMajorVersion}" -ge 2 ] && [ "${gpgMinorVersion}" -ge 1 ] && [ -f /etc/dracut.conf.d/crypt-public-key.gpg ]; then
        inst_multiple gpg-agent
        inst_multiple gpg-connect-agent
        inst_multiple /usr/libexec/scdaemon || derror "crypt-gpg: gnugpg with scdaemon required for smartcard support in the initramfs"
        cp "/etc/dracut.conf.d/crypt-public-key.gpg" "${initdir}/root/"
    elif [ -f /etc/dracut.conf.d/crypt-public-key.gpg ]; then
        dwarning "crypt-gpg: gnupg >= 2.1 required for smartcard support in the initramfs"
    fi
}
