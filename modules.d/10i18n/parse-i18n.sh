#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

inst_key_val() {
    local _value
    local _file
    _file=$1
    shift
    _value=$(getarg $@)
    if [ -n "${_value}" ]; then
        printf '%s="%s"\n' $1 ${_value} >> $_file
    fi
    unset _file
    unset _value
}

inst_key_val /etc/vconsole.conf KEYMAP      vconsole.keymap      KEYTABLE
inst_key_val /etc/vconsole.conf FONT        vconsole.font        SYSFONT 
inst_key_val /etc/vconsole.conf FONT_MAP    vconsole.font.map    CONTRANS 
inst_key_val /etc/vconsole.conf FONT_UNIMAP vconsole.font.unimap UNIMAP 
inst_key_val /etc/vconsole.conf UNICODE     vconsole.font.unicode
inst_key_val /etc/vconsole.conf EXT_KEYMAP  vconsole.keymap.ext

inst_key_val /etc/locale.conf   LANG   locale.LANG
inst_key_val /etc/locale.conf   LC_ALL locale.LC_ALL

if [ -f /etc/locale.conf ]; then
    . /etc/locale.conf
    export LANG
    export LC_ALL
fi
