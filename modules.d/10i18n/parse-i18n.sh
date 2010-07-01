#!/bin/sh

inst_key_val() {
    local value
    value=$(getarg $1)
    [ -n "${value}" ] && printf '%s="%s"\n' $1 ${value} >> $2
}


mkdir -p /etc/sysconfig
inst_key_val KEYMAP /etc/sysconfig/keyboard
inst_key_val EXT_KEYMAPS /etc/sysconfig/keyboard
inst_key_val UNICODE /etc/sysconfig/i18n
inst_key_val SYSFONT /etc/sysconfig/i18n
inst_key_val CONTRANS /etc/sysconfig/i18n
inst_key_val UNIMAP /etc/sysconfig/i18n
inst_key_val LANG /etc/sysconfig/i18n
inst_key_val LC_ALL /etc/sysconfig/i18n

if [ -f /etc/sysconfig/i18n ]; then
    . /etc/sysconfig/i18n
    export LANG
    export LC_ALL
fi
