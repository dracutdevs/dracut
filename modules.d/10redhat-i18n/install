#!/bin/bash
findkeymap () {
    local MAP=$1
    [[ ! -f $MAP ]] && \
	MAP=$(find /lib/kbd/keymaps -type f -name $MAP -o -name $MAP.\* | head -n1)
    [[ " $KEYMAPS " = *" $MAP "* ]] && return
    KEYMAPS="$KEYMAPS $MAP"
    case $MAP in
        *.gz) cmd=zgrep;;
        *.bz2) cmd=bzgrep;;
        *) cmd=grep ;;
    esac

    for INCL in $($cmd "^include " $MAP | cut -d' ' -f2 | tr -d '"'); do
        for FN in $(find /lib/kbd/keymaps -type f -name $INCL\*); do
            findkeymap $FN
        done
    done
}

# FIXME: i18n stuff isn't really distro-independent :/
if [[ -f /etc/sysconfig/keyboard || -f /etc/sysconfig/console/default.kmap ]]; then
    if [ -f /etc/sysconfig/console/default.kmap ]; then
        KEYMAP=/etc/sysconfig/console/default.kmap
    else
        . /etc/sysconfig/keyboard
        [[ $KEYTABLE && -d /lib/kbd/keymaps ]] && KEYMAP="$KEYTABLE.map"
    fi
    if [[ $KEYMAP ]]; then
        [ -f /etc/sysconfig/keyboard ] && inst /etc/sysconfig/keyboard
        inst loadkeys
        findkeymap $KEYMAP

        for FN in $KEYMAPS; do
            inst $FN
            case $FN in
                *.gz) gzip -d "$initdir$FN" ;;
                *.bz2) bzip2 -d "$initdir$FN" ;;
            esac
        done
    fi
fi

if [ -f /etc/sysconfig/i18n ]; then
    . /etc/sysconfig/i18n
    inst /etc/sysconfig/i18n
    [[ $SYSFONT ]] || SYSFONT=latarcyrheb-sun16
    inst setfont

    for FN in /lib/kbd/consolefonts/$SYSFONT.* ; do
        inst "$FN"
        case $FN in
            *.gz) gzip -d "$initdir$FN" ;;
            *.bz2) bzip2 -d "$initdir$FN" ;;
        esac
    done
    [[ $SYSFONTACM ]] && inst /lib/kbd/consoletrans/$SYSFONTACM
    [[ $UNIMAP ]] && inst /lib/kbd/unimaps/$UNIMAP
fi
