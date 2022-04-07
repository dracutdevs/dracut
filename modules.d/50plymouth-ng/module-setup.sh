#!/bin/bash

pkglib_dir() {
    local _dirs="/usr/lib/plymouth /usr/lib64/plymouth /usr/libexec/plymouth"
    if find_binary dpkg-architecture &> /dev/null; then
        local _arch
        _arch=$(dpkg-architecture -qDEB_HOST_MULTIARCH 2> /dev/null)
        [ -n "$_arch" ] && _dirs+=" /usr/lib/$_arch/plymouth"
    fi
    for _dir in $_dirs; do
        if [[ -x "$dracutsysrootdir""$_dir"/plymouthd-fd-escrow ]]; then
            echo "$_dir"
            return
        fi
        if [[ -x "$dracutsysrootdir""$_dir"/plymouth-populate-initrd ]]; then
            echo "$_dir"
            return
        fi
    done
}

plugin_dir() {
    local _dirs="/usr/lib/plymouth /usr/lib64/plymouth /usr/libexec/plymouth"
    if find_binary dpkg-architecture &> /dev/null; then
        local _arch
        _arch=$(dpkg-architecture -qDEB_HOST_MULTIARCH 2> /dev/null)
        [[ -n $_arch ]] && _dirs+=" /usr/lib/$_arch/plymouth"
    fi
    for _dir in $_dirs; do
        if [[ -d "$dracutsysrootdir""$_dir"/renderers ]]; then
            echo "$_dir"
            return
        fi
    done
}

# $1: Configuration file
# $2: Setting name
function read_setting_from_file() {
    grep -v '^#' "$1" 2> /dev/null \
        | awk 'BEGIN { FS="[=[:space:]]+"; OFS=""; ORS="" } $1 ~/^'"$2"'$/ { print $2 }'
}

# $1: Configuration file
function set_configured_theme_path_from_file() {
    [[ -z $CONFIGURED_THEME_DIR ]] && CONFIGURED_THEME_DIR=$(read_setting_from_file "$1" "ThemeDir")
    [[ -z $CONFIGURED_THEME_DIR ]] && CONFIGURED_THEME_DIR=/usr/share/plymouth/themes
    CONFIGURED_THEME_NAME=$(read_setting_from_file "$1" "Theme")
}

function set_theme_dir() {
    set_configured_theme_path_from_file "$dracutsysrootdir"/etc/plymouth/plymouthd.conf
    if [[ -z $CONFIGURED_THEME_DIR ]] || [[ ! -d "$dracutsysrootdir$CONFIGURED_THEME_DIR/$CONFIGURED_THEME_NAME" ]]; then
        set_configured_theme_path_from_file "$dracutsysrootdir"/usr/share/plymouth/plymouthd.defaults
    fi

    if [[ -n $CONFIGURED_THEME_DIR ]] && [[ -d $dracutsysrootdir$CONFIGURED_THEME_DIR ]]; then
        PLYMOUTH_THEME_DIR="$CONFIGURED_THEME_DIR"
    else
        PLYMOUTH_THEME_DIR=/usr/share/plymouth/themes
    fi
    PLYMOUTH_THEME_NAME=${CONFIGURED_THEME_NAME:-spinner}
}

# called by dracut
check() {
    [[ "$mount_needs" ]] && return 1
    [[ $(pkglib_dir) ]] || return 1

    require_binaries plymouthd plymouth plymouth-set-default-theme || return 1

    set_theme_dir
    [[ -n $PLYMOUTH_THEME_NAME ]] || return 1

    return 255
}

# called by dracut
depends() {
    echo drm
}

# called by dracut
install() {
    PKGLIBDIR=$(pkglib_dir)
    PLUGINDIR=$(plugin_dir)

    inst_multiple readlink

    inst_multiple plymouthd plymouth
    inst_multiple -o "$PKGLIBDIR"/plymouthd-fd-escrow

    inst_multiple -o "$PLUGINDIR/renderers/drm.so"
    inst_multiple "$PLUGINDIR/renderers/frame-buffer.so"

    set_theme_dir
    inst_dir "$PLYMOUTH_THEME_DIR"

    inst_multiple "$PLUGINDIR"/text.so "$PLUGINDIR"/details.so
    inst_recur "$PLYMOUTH_THEME_DIR"/text
    inst_recur "$PLYMOUTH_THEME_DIR"/details

    PLYMOUTH_MODULE_NAME=$(grep "ModuleName *= *" "$dracutsysrootdir$PLYMOUTH_THEME_DIR/$PLYMOUTH_THEME_NAME/$PLYMOUTH_THEME_NAME.plymouth" | sed 's/ModuleName *= *//')
    PLYMOUTH_IMAGE_DIR=$(grep "ImageDir *= *" "$dracutsysrootdir$PLYMOUTH_THEME_DIR/$PLYMOUTH_THEME_NAME/$PLYMOUTH_THEME_NAME.plymouth" | sed 's/ImageDir *= *//')

    inst_multiple -o "$PLUGINDIR/$PLYMOUTH_MODULE_NAME.so"
    inst_recur "$PLYMOUTH_THEME_DIR/$PLYMOUTH_THEME_NAME"

    if [[ $PLYMOUTH_IMAGE_DIR != "$PLYMOUTH_THEME_DIR/$PLYMOUTH_THEME_NAME" ]] && [[ -n $PLYMOUTH_IMAGE_DIR ]] && [[ -d "$dracutsysrootdir$PLYMOUTH_IMAGE_DIR" ]]; then
        inst_recur "$PLYMOUTH_IMAGE_DIR"
    fi

    inst_multiple \
        /usr/share/plymouth/plymouthd.defaults \
        /etc/plymouth/plymouthd.conf

    inst_multiple -o /usr/share/plymouth/themes/default.plymouth

    inst_multiple -o "/usr/share/plymouth/*.png"

    inst_multiple -o /etc/system-release

    inst_hook emergency 50 "$moddir"/plymouth-emergency.sh

    if dracut_module_included "systemd"; then
        inst_multiple \
            "$systemdsystemunitdir"/systemd-ask-password-plymouth.path \
            "$systemdsystemunitdir"/systemd-ask-password-plymouth.service \
            "$systemdsystemunitdir"/plymouth-switch-root.service \
            "$systemdsystemunitdir"/plymouth-start.service \
            "$systemdsystemunitdir"/plymouth-quit.service \
            "$systemdsystemunitdir"/plymouth-quit-wait.service \
            "$systemdsystemunitdir"/plymouth-reboot.service \
            "$systemdsystemunitdir"/plymouth-kexec.service \
            "$systemdsystemunitdir"/plymouth-poweroff.service \
            "$systemdsystemunitdir"/plymouth-halt.service \
            "$systemdsystemunitdir"/initrd-switch-root.target.wants/plymouth-switch-root.service \
            "$systemdsystemunitdir"/initrd-switch-root.target.wants/plymouth-start.service \
            "$systemdsystemunitdir"/sysinit.target.wants/plymouth-start.service \
            "$systemdsystemunitdir"/multi-user.target.wants/plymouth-quit.service \
            "$systemdsystemunitdir"/multi-user.target.wants/plymouth-quit-wait.service \
            "$systemdsystemunitdir"/reboot.target.wants/plymouth-reboot.service \
            "$systemdsystemunitdir"/kexec.target.wants/plymouth-kexec.service \
            "$systemdsystemunitdir"/poweroff.target.wants/plymouth-poweroff.service \
            "$systemdsystemunitdir"/halt.target.wants/plymouth-halt.service
    else
        inst_hook pre-trigger 10 "$moddir"/plymouth-pretrigger.sh
        inst_hook pre-pivot 90 "$moddir"/plymouth-newroot.sh
    fi
}
