#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [ -f /etc/redhat-release ]
}

depends() {
    return 0
}

install() {
    local _line
    local _dracut_rpm_version
    if [ -e "$moddir/dracut-version" ]; then
        _dracut_rpm_version=$(cat "$moddir/dracut-version")
        inst "$moddir/dracut-version" /lib/dracut/$_dracut_rpm_version
    else
        if rpm -qf $(type -P $0) &>/dev/null; then
            _dracut_rpm_version=$(rpm -qf --qf '%{name}-%{version}-%{release}\n' $(type -P $0) | { ver="";while read _line;do ver=$_line;done;echo $ver;} )
            mkdir -m 0755 -p $initdir/lib/dracut
            echo $_dracut_rpm_version > $initdir/lib/dracut/$_dracut_rpm_version
        fi
    fi
    inst_hook cmdline 01 "$moddir/version.sh"

}

