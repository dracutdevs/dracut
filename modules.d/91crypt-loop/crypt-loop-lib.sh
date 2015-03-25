#!/bin/sh

command -v ask_for_password >/dev/null || . /lib/dracut-crypt-lib.sh

# loop_decrypt mnt_point keypath keydev device
#
# Decrypts symmetrically encrypted key to standard output.
#
# mnt_point - mount point where <keydev> is already mounted
# keypath - LUKS encrypted loop file path relative to <mnt_point>
# keydev - device on which key resides; only to display in prompt
# device - device to be opened by cryptsetup; only to display in prompt
loop_decrypt() {
    local mntp="$1"
    local keypath="$2"
    local keydev="$3"
    local device="$4"

    local key="/dev/mapper/${mntp##*/}"

    if [ ! -b $key ]; then
        local loopdev=$(losetup -f "${mntp}/${keypath}" --show)
        local opts="-d - luksOpen $loopdev ${key##*/}"

        ask_for_password \
            --cmd "cryptsetup $opts" \
            --prompt "Password ($keypath on $keydev for $device)" \
            --tty-echo-off

        [ -b $key ] || die "Failed to unlock $keypath on $keydev for $device."

        initqueue --onetime --finished --unique --name "crypt-loop-cleanup-10-${key##*/}" \
            $(command -v cryptsetup) "luksClose $key"
        initqueue --onetime --finished --unique --name "crypt-loop-cleanup-20-${loopdev##*/}" \
            $(command -v losetup) "-d $loopdev"
    fi

    cat $key
}
