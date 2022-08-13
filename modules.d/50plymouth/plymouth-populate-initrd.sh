#!/bin/sh

PLYMOUTH_LOGO_FILE="/usr/share/pixmaps/system-logo-white.png"
PLYMOUTH_THEME=$(plymouth-set-default-theme)

inst_multiple plymouthd plymouth \
    /etc/system-release

[ -e "${PLYMOUTH_LOGO_FILE}" ] && inst_simple "${PLYMOUTH_LOGO_FILE}"

mkdir -m 0755 -p "${initdir}/usr/share/plymouth"

inst_libdir_file "plymouth/text.so" "plymouth/details.so"

if [ -n "$hostonly" ]; then
    inst_multiple \
        "/usr/share/plymouth/themes/details/details.plymouth" \
        "/usr/share/plymouth/themes/text/text.plymouth"

    if [ -d "$dracutsysrootdir/usr/share/plymouth/themes/$PLYMOUTH_THEME" ]; then
        for x in "/usr/share/plymouth/themes/$PLYMOUTH_THEME"/*; do
            [ -f "$dracutsysrootdir$x" ] && inst "$x"
        done
    fi

    if [ -L "$dracutsysrootdir/usr/share/plymouth/themes/default.plymouth" ]; then
        inst /usr/share/plymouth/themes/default.plymouth
        # Install plugin for this theme
        PLYMOUTH_PLUGIN=$(grep "^ModuleName=" "$dracutsysrootdir"/usr/share/plymouth/themes/default.plymouth | while read -r _ b _ || [ -n "$b" ]; do echo "$b"; done)
        inst_libdir_file "plymouth/${PLYMOUTH_PLUGIN}.so"
    fi
else
    for x in "$dracutsysrootdir"/usr/share/plymouth/themes/text/* \
        "$dracutsysrootdir"/usr/share/plymouth/themes/details/*; do
        [ -f "$x" ] || continue
        THEME_DIR=$(dirname "${x#"$dracutsysrootdir"}")
        mkdir -m 0755 -p "${initdir}/$THEME_DIR"
        inst_multiple "${x#"$dracutsysrootdir"}"
    done
    ln -s text/text.plymouth "${initdir}"/usr/share/plymouth/themes/default.plymouth 2>&1
fi
