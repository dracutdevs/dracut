#!/bin/sh

depends() {
    shells='dash bash mksh busybox'
    for shell in $shells; do
        if dracut_module_included "$shell"; then
            echo "$shell"
            return 0
        fi
    done

    shell=$(realpath -e /bin/sh)
    shell=${shell##*/}

    echo "$shell"
    return 0
}
