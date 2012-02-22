#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
PLYMOUTH_LOGO_FILE="/usr/share/pixmaps/system-logo-white.png"
PLYMOUTH_THEME=$(plymouth-set-default-theme)

inst /sbin/plymouthd /bin/plymouthd
dracut_install /bin/plymouth \
    "${PLYMOUTH_LOGO_FILE}" \
    /etc/system-release

mkdir -m 0755 -p "${initdir}/usr/share/plymouth"

if [[ $hostonly ]]; then
    dracut_install "${usrlibdir}/plymouth/text.so" \
        "${usrlibdir}/plymouth/details.so" \
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
        inst "${usrlibdir}/plymouth/${PLYMOUTH_PLUGIN}.so"
    fi
else
    for x in /usr/share/plymouth/themes/{text,details}/* ; do
        [[ -f "$x" ]] || continue
        THEME_DIR=$(dirname "$x")
        mkdir -m 0755 -p "${initdir}/$THEME_DIR"
        dracut_install "$x"
    done
    for x in "${usrlibdir}"/plymouth/{text,details}.so ; do
        [[ -f "$x" ]] || continue
        [[ "$x" != "${x%%/label.so}" ]] && continue
        dracut_install "$x"
    done
    (
        cd ${initdir}/usr/share/plymouth/themes;
        ln -s text/text.plymouth default.plymouth 2>&1;
    )
fi
