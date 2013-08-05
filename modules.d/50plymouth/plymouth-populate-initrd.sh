#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
PLYMOUTH_LOGO_FILE="/usr/share/pixmaps/system-logo-white.png"
PLYMOUTH_THEME=$(plymouth-set-default-theme)

inst_multiple plymouthd plymouth \
    "${PLYMOUTH_LOGO_FILE}" \
    /etc/system-release

mkdir -m 0755 -p "${initdir}/usr/share/plymouth"

inst_libdir_file "plymouth/text.so" "plymouth/details.so"

if [[ $hostonly ]]; then
    inst_multiple \
        "/usr/share/plymouth/themes/details/details.plymouth" \
        "/usr/share/plymouth/themes/text/text.plymouth" \

    if [[ -d /usr/share/plymouth/themes/${PLYMOUTH_THEME} ]]; then
        for x in "/usr/share/plymouth/themes/${PLYMOUTH_THEME}"/* ; do
            [[ -f "$x" ]] || break
            inst $x
        done
    fi

    if [ -L /usr/share/plymouth/themes/default.plymouth ]; then
        inst /usr/share/plymouth/themes/default.plymouth
        # Install plugin for this theme
        PLYMOUTH_PLUGIN=$(grep "^ModuleName=" /usr/share/plymouth/themes/default.plymouth | while read a b c; do echo $b; done;)
        inst_libdir_file "plymouth/${PLYMOUTH_PLUGIN}.so"
    fi
else
    for x in /usr/share/plymouth/themes/{text,details}/* ; do
        [[ -f "$x" ]] || continue
        THEME_DIR=$(dirname "$x")
        mkdir -m 0755 -p "${initdir}/$THEME_DIR"
        inst_multiple "$x"
    done
    (
        cd ${initdir}/usr/share/plymouth/themes;
        ln -s text/text.plymouth default.plymouth 2>&1;
    )
fi
