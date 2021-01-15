#!/usr/bin/bash

# called by dracut
check() {
    require_binaries /usr/bin/dash
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    # If another shell is already installed, do not use dash
    [[ -x $initdir/usr/bin/sh ]] && return

    # Prefer dash as /bin/sh if it is available.
    inst /usr/bin/dash && ln -sf dash "${initdir}/bin/sh"
}

