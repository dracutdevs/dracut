#!/bin/sh

## Dracut pre-pivot hook

command -v info &>/dev/null && \
    command -v warn &>/dev/null && \
    command -v ismounted &>/dev/null || . /lib/dracut-lib.sh

move_mpoints() {
    local _d _src _dst
    for _d in /run /sys /dev /proc; do
        ismounted "${_d}" && mkdir -p "${NEWROOT}${_d}" && ! ismounted "${NEWROOT}${_d}" || continue
        set -- $( (cat /proc/mounts || cat ${NEWROOT}/proc/mounts ) | cut -f2 -d\  | grep -wE "^${_d}" )
        if mount --move "${_d}" "${NEWROOT}${_d}"; then
            info "mount --move ${_d} ${NEWROOT}${_d}"
            _src=${NEWROOT}
            _dst=
        else
            warn "Eror on: mount --move ${_d} ${NEWROOT}${_d}"
            _src=
            _dst=${NEWROOT}
        fi
        (
            local _dd
            for _dd ; do
                if mount --bind "${_src}${_dd}" "${_dst}${_dd}"; then
                    info "mount --bind ${_src}${_dd} ${_dst}${_dd}"
                else
                    warn "Error on: mount --bind ${_src}${_dd} ${_dst}${_dd}"
                fi
            done
            :
        ) &
    done
    while fg; do :; done &>/dev/null
}

switch_root --help 2>&1 | grep -qi busybox &>/dev/null && move_mpoints
