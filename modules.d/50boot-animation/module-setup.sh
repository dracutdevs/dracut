#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    # shellcheck disable=SC2043
    for module in plymouth-ng; do
        if dracut_module_included "$module"; then
            splash_backend="$module"
            break
        fi
    done

    if [ -z "$splash_backend" ]; then
        if [[ -e $dracutsysrootdir$systemdsystemunitdir/plymouth-start.service ]]; then
            splash_backend="plymouth-ng"
        fi
    fi
    echo "$splash_backend"
    return 0
}

# called by dracut
installkernel() {
    return 0
}

# called by dracut
install() {
    return 0
}
