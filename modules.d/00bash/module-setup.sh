#!/usr/bin/bash

# called by dracut
check() {
    require_binaries /usr/bin/bash
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    # If another shell is already installed, do not use bash
    [[ -x $initdir/usr/bin/sh ]] && return

    # Prefer bash as /bin/sh if it is available.
    inst /usr/bin/bash && ln -sf bash "${initdir}/usr/bin/sh"
}

