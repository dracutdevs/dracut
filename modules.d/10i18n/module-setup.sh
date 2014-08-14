#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [[ "$mount_needs" ]] && return 1

    require_binaries setfont loadkeys kbd_mode || return 1

    return 0
}

depends() {
    return 0
}

install() {
    if dracut_module_included "systemd"; then
        unset FONT
        unset KEYMAP
        [[ -f /etc/vconsole.conf ]] && . /etc/vconsole.conf
    fi

    KBDSUBDIRS=consolefonts,consoletrans,keymaps,unimaps
    DEFAULT_FONT="${i18n_default_font:-LatArCyrHeb-16}"
    I18N_CONF="/etc/locale.conf"
    VCONFIG_CONF="/etc/vconsole.conf"

    # This is from 10redhat-i18n.
    findkeymap () {
        local MAP=$1
        [[ ! -f $MAP ]] && \
            MAP=$(find ${kbddir}/keymaps -type f -name $MAP -o -name $MAP.\* | head -n1)
        [[ " $KEYMAPS " = *" $MAP "* ]] && return
        KEYMAPS="$KEYMAPS $MAP"
        case $MAP in
            *.gz) cmd=zgrep;;
            *.bz2) cmd=bzgrep;;
            *) cmd=grep ;;
        esac

        for INCL in $($cmd "^include " $MAP | while read a a b; do echo ${a//\"/}; done); do
            for FN in $(find ${kbddir}/keymaps -type f -name $INCL\*); do
                findkeymap $FN
            done
        done
    }

# Function gathers variables from distributed files among the tree, maps to
# specified names and prints the result in format "new-name=value".
#
# $@ = list in format specified below (BNF notation)
#
# <list> ::= <element> | <element> " " <list>
# <element> ::= <conf-file-name> ":" <map-list>
# <map-list> ::= <mapping> | <mapping> "," <map-list>
# <mapping> ::= <src-var> "-" <dst-var> | <src-var>
#
# We assume no whitespace are allowed between symbols.
# <conf-file-name> is a file holding <src-var> in your system.
# <src-var> is a variable holding value of meaning the same as <dst-var>.
# <dst-var> is a variable which will be set up inside initramfs.
# If <dst-var> has the same name as <src-var> we can omit <dst-var>.
#
# Example:
# /etc/conf.d/keymaps:KEYMAP,extended_keymaps-EXT_KEYMAPS
# <list> = /etc/conf.d/keymaps:KEYMAP,extended_keymaps-EXT_KEYMAPS
# <element> = /etc/conf.d/keymaps:KEYMAP,extended_keymaps-EXT_KEYMAPS
# <conf-file-name> = /etc/conf.d/keymaps
# <map-list> = KEYMAP,extended_keymaps-EXT_KEYMAPS
# <mapping> = KEYMAP
# <src-var> = KEYMAP
# <mapping> = extended_keymaps-EXT_KEYMAPS
# <src-var> = extended_keymaps
# <dst-var> = EXT_KEYMAPS
    gather_vars() {
        local item map value

        for item in $@
        do
            item=(${item/:/ })
            for map in ${item[1]//,/ }
            do
                map=(${map//-/ })
                if [[ -f "${item[0]}" ]]; then
                    value=$(grep "^${map[0]}=" "${item[0]}")
                    value=${value#*=}
                    echo "${map[1]:-${map[0]}}=${value}"
                fi
            done
        done
    }

    install_base() {
        inst_multiple setfont loadkeys kbd_mode stty

        if ! dracut_module_included "systemd"; then
            inst ${moddir}/console_init.sh /lib/udev/console_init
            inst_rules ${moddir}/10-console.rules
            inst_hook cmdline 20 "${moddir}/parse-i18n.sh"
        fi
    }

    install_all_kbd() {
        local rel f

        for _src in $(eval echo ${kbddir}/{${KBDSUBDIRS}}); do
            inst_dir "$_src"
            cp --reflink=auto --sparse=auto -prfL -t "${initdir}/${_src}" "$_src"/*
        done

        # remove unnecessary files
        rm -f -- "${initdir}${kbddir}/consoletrans/utflist"
        find "${initdir}${kbddir}/" -name README\* -delete
        find "${initdir}${kbddir}/" -name '*.gz' -print -quit \
            | while read line; do
            inst_multiple gzip
            done

        find "${initdir}${kbddir}/" -name '*.bz2' -print -quit \
            | while read line; do
            inst_multiple bzip2
            done
    }

    install_local_i18n() {
        local map

        eval $(gather_vars ${i18n_vars})
        [ -f $I18N_CONF ] && . $I18N_CONF
        [ -f $VCONFIG_CONF ] && . $VCONFIG_CONF

        shopt -q -s nocasematch
        if [[ ${UNICODE} ]]
        then
            if [[ ${UNICODE} = YES || ${UNICODE} = 1 ]]
            then
                UNICODE=1
            elif [[ ${UNICODE} = NO || ${UNICODE} = 0 ]]
            then
                UNICODE=0
            else
                UNICODE=''
            fi
        fi
        if [[ ! ${UNICODE} && ${LANG} =~ .*\.UTF-?8 ]]
        then
            UNICODE=1
        fi
        shopt -q -u nocasematch

        # Gentoo user may have KEYMAP set to something like "-u pl2",
        KEYMAP=${KEYMAP#-* }

        # KEYTABLE is a bit special - it defines base keymap name and UNICODE
        # determines whether non-UNICODE or UNICODE version is used

        if [[ ${KEYTABLE} ]]; then
           if [[ ${UNICODE} == 1 ]]; then
               [[ ${KEYTABLE} =~ .*\.uni.* ]] || KEYTABLE=${KEYTABLE%.map*}.uni
           fi
           KEYMAP=${KEYTABLE}
        fi

        # I'm not sure of the purpose of UNIKEYMAP and GRP_TOGGLE.  They were in
        # original redhat-i18n module.  Anyway it won't hurt.
        EXT_KEYMAPS+=\ ${UNIKEYMAP}\ ${GRP_TOGGLE}

        [[ ${KEYMAP} ]] || {
            dinfo 'No KEYMAP configured.'
            return 1
        }

        findkeymap ${KEYMAP}

        for map in ${EXT_KEYMAPS}
        do
            ddebug "Adding extra map: ${map}"
            findkeymap ${map}
        done

        inst_opt_decompress ${KEYMAPS}

        inst_opt_decompress ${kbddir}/consolefonts/${DEFAULT_FONT}.*

        if [[ ${FONT} ]] && [[ ${FONT} != ${DEFAULT_FONT} ]]
        then
            FONT=${FONT%.psf*}
            inst_opt_decompress ${kbddir}/consolefonts/${FONT}.*
        fi

        if [[ ${FONT_MAP} ]]
        then
            FONT_MAP=${FONT_MAP%.trans}
            inst_simple ${kbddir}/consoletrans/${FONT_MAP}.trans
        fi

        if [[ ${FONT_UNIMAP} ]]
        then
            FONT_UNIMAP=${FONT_UNIMAP%.uni}
            inst_simple ${kbddir}/unimaps/${FONT_UNIMAP}.uni
        fi

        if dracut_module_included "systemd" && [[ -f ${I18N_CONF} ]]; then
            inst_simple ${I18N_CONF}
        else
            mksubdirs ${initdir}${I18N_CONF}
            print_vars LC_ALL LANG >> ${initdir}${I18N_CONF}
        fi

        if dracut_module_included "systemd" && [[ -f ${VCONFIG_CONF} ]]; then
            inst_simple ${VCONFIG_CONF}
        else
            mksubdirs ${initdir}${VCONFIG_CONF}
            print_vars KEYMAP EXT_KEYMAPS UNICODE FONT FONT_MAP FONT_UNIMAP >> ${initdir}${VCONFIG_CONF}
        fi

        return 0
    }

    checks() {
        for kbddir in ${kbddir} /usr/lib/kbd /lib/kbd /usr/share /usr/share/kbd
        do
            [[ -d "${kbddir}" ]] && \
                for dir in ${KBDSUBDIRS//,/ }
            do
                [[ -d "${kbddir}/${dir}" ]] && continue
                false
            done && break
            kbddir=''
        done

        [[ -f $I18N_CONF && -f $VCONFIG_CONF ]] || \
            [[ ! ${hostonly} || ${i18n_vars} ]] || {
            derror 'i18n_vars not set!  Please set up i18n_vars in ' \
                'configuration file.'
        }
        return 0
    }

    if checks; then
        install_base

        if [[ ${hostonly} ]] && ! [[ ${i18n_install_all} == "yes" ]]; then
            install_local_i18n || install_all_kbd
        else
            install_all_kbd
        fi
    fi
}
