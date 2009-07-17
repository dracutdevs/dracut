initrdargs="$initrdargs rd_plytheme" 

PLYMOUTH_THEMEDIR=/usr/share/plymouth/themes
PLYMOUTH_THEME=$(getarg rd_plytheme=)
if [ -n "$PLYMOUTH_THEME" ]; then
    if [ -f "${PLYMOUTH_THEMEDIR}/${PLYMOUTH_THEME}/${PLYMOUTH_THEME}.plymouth" ]; then
	info "Setting theme $PLYMOUTH_THEME"
	(
	    cd $PLYMOUTH_THEMEDIR;
	    ln -fs "${PLYMOUTH_THEME}/${PLYMOUTH_THEME}.plymouth" default.plymouth 2>&1 | vinfo;       
	)
    else
	warn "Theme $PLYMOUTH_THEME not found!"
    fi
fi

unset PLYMOUTH_THEME
unset PLYMOUTH_THEMEDIR

