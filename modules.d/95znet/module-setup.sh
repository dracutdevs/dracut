#!/bin/bash

# called by dracut
check() {
    arch=${DRACUT_ARCH:-$(uname -m)}
    [ "$arch" = "s390" -o "$arch" = "s390x" ] || return 1

    require_binaries grep sed seq readlink chzdev || return 1

    return 0
}

# called by dracut
depends() {
    echo bash
    return 0
}

# called by dracut
installkernel() {
    instmods ctcm lcs qeth qeth_l2 qeth_l3
}

# called by dracut
install() {
    inst_hook cmdline 30 "$moddir/parse-ccw.sh"
    inst_multiple grep sed seq readlink chzdev
    if [[ $hostonly ]]; then
        local _tempfile
        _tempfile=$(mktemp --tmpdir="${DRACUT_TMPDIR}" dracut-zdev.XXXXXX)
        {
            chzdev qeth --export - --configured --persistent --quiet --type
            chzdev lcs --export - --configured --persistent --quiet --type
            chzdev ctc --export - --configured --persistent --quiet --type
        } 2> /dev/null > "$_tempfile"
        ddebug < "$_tempfile"
        chzdev --import "$_tempfile" --persistent --base "/etc=$initdir/etc" \
            --yes --no-root-update --force 2>&1 | ddebug
        lszdev --configured --persistent --info \
            --base "/etc=$initdir/etc" 2>&1 | ddebug
        rm -f "$_tempfile"
        # these are purely generated udev rules so we have to glob expand
        # within $initdir and strip the $initdir prefix for mark_hostonly
        local -a _array
        # shellcheck disable=SC2155
        local _nullglob=$(shopt -p nullglob)
        shopt -u nullglob
        # shellcheck disable=SC2086
        readarray -t _array < <(
            ls -1 $initdir/etc/udev/rules.d/41-*.rules 2> /dev/null
        )
        [[ ${#_array[@]} -gt 0 ]] && mark_hostonly "${_array[@]#$initdir}"
        # shellcheck disable=SC2086
        readarray -t _array < <(
            ls -1 $initdir/etc/modprobe.d/s390x-*.conf 2> /dev/null
        )
        [[ ${#_array[@]} -gt 0 ]] && mark_hostonly "${_array[@]#$initdir}"
        $_nullglob
    fi
}
