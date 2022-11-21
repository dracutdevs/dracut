#!/bin/sh

_do_md_shutdown() {
    local ret
    local final="$1"
    info "Waiting for mdraid devices to be clean."
    mdadm -vv --wait-clean --scan | vinfo
    ret=$?
    info "Disassembling mdraid devices."
    mdadm -vv --stop --scan | vinfo
    ret=$((ret + $?))
    if [ "x$final" != "x" ]; then
        info "/proc/mdstat:"
        vinfo < /proc/mdstat
    fi
    return $ret
}

if command -v mdadm > /dev/null; then
    _do_md_shutdown "$1"
else
    :
fi
