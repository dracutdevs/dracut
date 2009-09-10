inst_key_val()
{
    local value
    value=$(getarg $1)
    [ -n "$value" ] && printf '%s="%s"\n' $1 $value >> $2
}

mkdir -p /etc/sysconfig
inst_key_val KEYBOARDTYPE /etc/sysconfig/keyboard
inst_key_val KEYTABLE /etc/sysconfig/keyboard
inst_key_val SYSFONT /etc/sysconfig/i18n
inst_key_val SYSFONTACM /etc/sysconfig/i18n
inst_key_val UNIMAP /etc/sysconfig/i18n
inst_key_val LANG /etc/sysconfig/i18n

if [ -f /etc/sysconfig/i18n ]; then
    . /etc/sysconfig/i18n
    export LANG
fi

