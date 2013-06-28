#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

inst_key_val() {
    local _value
    local _file
    local _default
    _default=$1
    shift
    _file=$1
    shift
    _value=$(getarg $@)
    [ -z "${_value}" ] && _value=$_default
    if [ -n "${_value}" ]; then
        printf '%s="%s"\n' $2 ${_value} >> $_file
    fi
    unset _file
    unset _value
}

inst_key_val '' /etc/vconsole.conf vconsole.keymap      KEYMAP      -d KEYTABLE
inst_key_val '' /etc/vconsole.conf vconsole.font        FONT        -d SYSFONT
inst_key_val '' /etc/vconsole.conf vconsole.font.map    FONT_MAP    -d CONTRANS
inst_key_val '' /etc/vconsole.conf vconsole.font.unimap FONT_UNIMAP -d UNIMAP
inst_key_val 1  /etc/vconsole.conf vconsole.font.unicode UNICODE vconsole.unicode
inst_key_val '' /etc/vconsole.conf vconsole.keymap.ext  EXT_KEYMAP

inst_key_val '' /etc/locale.conf   locale.LANG   LANG
inst_key_val '' /etc/locale.conf   locale.LC_ALL LC_ALL

if [ -f /etc/locale.conf ]; then
    . /etc/locale.conf
    export LANG
    export LC_ALL
fi

if [ -n "$DRACUT_SYSTEMD" ]; then
    rm -f -- /etc/udev/rules.d/10-console.rules
    rm -f -- /lib/udev/rules.d/10-console.rules
    rm -f -- /lib/udev/console_init
fi
