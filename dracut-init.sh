#!/bin/bash
#
# functions used only by dracut and dracut modules
#
# Copyright 2005-2009 Red Hat, Inc.  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
export LC_MESSAGES=C

# is_func <command>
# Check whether $1 is a function.
is_func() {
    [[ "$(type -t "$1")" = "function" ]]
}

if ! [[ $dracutbasedir ]]; then
    dracutbasedir=${BASH_SOURCE[0]%/*}
    [[ $dracutbasedir = dracut-functions* ]] && dracutbasedir="."
    [[ $dracutbasedir ]] || dracutbasedir="."
    dracutbasedir="$(readlink -f $dracutbasedir)"
fi

if ! is_func dinfo >/dev/null 2>&1; then
    . "$dracutbasedir/dracut-logger.sh"
    dlog_init
fi

if ! [[ $initdir ]]; then
    dfatal "initdir not set"
    exit 1
fi

if ! [[ -d $initdir ]]; then
    mkdir -p "$initdir"
fi

if [[ $DRACUT_KERNEL_LAZY ]] && ! [[ $DRACUT_KERNEL_LAZY_HASHDIR ]]; then
    if ! [[ -d "$initdir/.kernelmodseen" ]]; then
        mkdir -p "$initdir/.kernelmodseen"
    fi
    DRACUT_KERNEL_LAZY_HASHDIR="$initdir/.kernelmodseen"
fi

if ! [[ $kernel ]]; then
    kernel=$(uname -r)
    export kernel
fi

srcmods="/lib/modules/$kernel/"

[[ $drivers_dir ]] && {
    if ! command -v kmod &>/dev/null && vercmp "$(modprobe --version | cut -d' ' -f3)" lt 3.7; then
        dfatal 'To use --kmoddir option module-init-tools >= 3.7 is required.'
        exit 1
    fi
    srcmods="$drivers_dir"
}
export srcmods

# export standard hookdirs
[[ $hookdirs ]] || {
    hookdirs="cmdline pre-udev pre-trigger netroot "
    hookdirs+="initqueue initqueue/settled initqueue/online initqueue/finished initqueue/timeout "
    hookdirs+="pre-mount pre-pivot cleanup mount "
    hookdirs+="emergency shutdown-emergency pre-shutdown shutdown "
    export hookdirs
}

. $dracutbasedir/dracut-functions.sh

# Detect lib paths
if ! [[ $libdirs ]] ; then
    if [[ "$(ldd /bin/sh)" == */lib64/* ]] &>/dev/null \
        && [[ -d /lib64 ]]; then
        libdirs+=" /lib64"
        [[ -d /usr/lib64 ]] && libdirs+=" /usr/lib64"
    else
        libdirs+=" /lib"
        [[ -d /usr/lib ]] && libdirs+=" /usr/lib"
    fi

    libdirs+=" $(ldconfig_paths)"

    export libdirs
fi

# helper function for check() in module-setup.sh
# to check for required installed binaries
# issues a standardized warning message
require_binaries() {
    local _module_name="${moddir##*/}"
    local _ret=0

    if [[ "$1" = "-m" ]]; then
        _module_name="$2"
        shift 2
    fi

    for cmd in "$@"; do
        if ! find_binary "$cmd" &>/dev/null; then
            dinfo "dracut module '${_module_name#[0-9][0-9]}' will not be installed, because command '$cmd' could not be found!"
            ((_ret++))
        fi
    done
    return $_ret
}

require_any_binary() {
    local _module_name="${moddir##*/}"
    local _ret=1

    if [[ "$1" = "-m" ]]; then
        _module_name="$2"
        shift 2
    fi

    for cmd in "$@"; do
        if find_binary "$cmd" &>/dev/null; then
            _ret=0
            break
        fi
    done

    if (( $_ret != 0 )); then
        dinfo "$_module_name: Could not find any command of '$@'!"
        return 1
    fi

    return 0
}

dracut_need_initqueue() {
    >"$initdir/lib/dracut/need-initqueue"
}

dracut_module_included() {
    [[ " $mods_to_load $modules_loaded " == *\ $*\ * ]]
}

if ! [[ $DRACUT_INSTALL ]]; then
    DRACUT_INSTALL=$(find_binary dracut-install)
fi

if ! [[ $DRACUT_INSTALL ]] && [[ -x $dracutbasedir/dracut-install ]]; then
    DRACUT_INSTALL=$dracutbasedir/dracut-install
elif ! [[ $DRACUT_INSTALL ]] && [[ -x $dracutbasedir/install/dracut-install ]]; then
    DRACUT_INSTALL=$dracutbasedir/install/dracut-install
fi

if ! [[ -x $DRACUT_INSTALL ]]; then
    dfatal "dracut-install not found!"
    exit 10
fi

[[ $DRACUT_RESOLVE_LAZY ]] || export DRACUT_RESOLVE_DEPS=1
inst_dir() {
    [[ -e ${initdir}/"$1" ]] && return 0  # already there
    $DRACUT_INSTALL ${initdir:+-D "$initdir"} -d "$@"
    (($? != 0)) && derror $DRACUT_INSTALL ${initdir:+-D "$initdir"} -d "$@" || :
}

inst() {
    local _hostonly_install
    if [[ "$1" == "-H" ]]; then
        _hostonly_install="-H"
        shift
    fi
    [[ -e ${initdir}/"${2:-$1}" ]] && return 0  # already there
    $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l} ${DRACUT_FIPS_MODE:+-f} ${_hostonly_install:+-H} "$@"
    (($? != 0)) && derror $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l} ${DRACUT_FIPS_MODE:+-f} ${_hostonly_install:+-H} "$@" || :
}

inst_simple() {
    local _hostonly_install
    if [[ "$1" == "-H" ]]; then
        _hostonly_install="-H"
        shift
    fi
    [[ -e ${initdir}/"${2:-$1}" ]] && return 0  # already there
    [[ -e $1 ]] || return 1  # no source
    $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${_hostonly_install:+-H} "$@"
    (($? != 0)) && derror $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${_hostonly_install:+-H} "$@" || :
}

inst_symlink() {
    local _hostonly_install
    if [[ "$1" == "-H" ]]; then
        _hostonly_install="-H"
        shift
    fi
    [[ -e ${initdir}/"${2:-$1}" ]] && return 0  # already there
    [[ -L $1 ]] || return 1
    $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l}  ${DRACUT_FIPS_MODE:+-f} ${_hostonly_install:+-H} "$@"
    (($? != 0)) && derror $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l}  ${DRACUT_FIPS_MODE:+-f} ${_hostonly_install:+-H} "$@" || :
}

inst_multiple() {
    local _ret
    $DRACUT_INSTALL ${initdir:+-D "$initdir"} -a ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l}  ${DRACUT_FIPS_MODE:+-f} "$@"
    _ret=$?
    (($_ret != 0)) && derror $DRACUT_INSTALL ${initdir:+-D "$initdir"} -a ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l}  ${DRACUT_FIPS_MODE:+-f} ${_hostonly_install:+-H} "$@" || :
    return $_ret
}

dracut_install() {
    inst_multiple "$@"
}

inst_library() {
    local _hostonly_install
    if [[ "$1" == "-H" ]]; then
        _hostonly_install="-H"
        shift
    fi
    [[ -e ${initdir}/"${2:-$1}" ]] && return 0  # already there
    [[ -e $1 ]] || return 1  # no source
    $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l}  ${DRACUT_FIPS_MODE:+-f} ${_hostonly_install:+-H} "$@"
    (($? != 0)) && derror $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l}  ${DRACUT_FIPS_MODE:+-f} ${_hostonly_install:+-H} "$@" || :
}

inst_binary() {
    $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l}  ${DRACUT_FIPS_MODE:+-f} "$@"
    (($? != 0)) && derror $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l}  ${DRACUT_FIPS_MODE:+-f} "$@" || :
}

inst_script() {
    $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l} ${DRACUT_FIPS_MODE:+-f} "$@"
    (($? != 0)) && derror $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} ${DRACUT_RESOLVE_DEPS:+-l}  ${DRACUT_FIPS_MODE:+-f} "$@" || :
}

mark_hostonly() {
    for i in "$@"; do
        echo "$i" >> "$initdir/lib/dracut/hostonly-files"
    done
}

# find symlinks linked to given library file
# $1 = library file
# Function searches for symlinks by stripping version numbers appended to
# library filename, checks if it points to the same target and finally
# prints the list of symlinks to stdout.
#
# Example:
# rev_lib_symlinks libfoo.so.8.1
# output: libfoo.so.8 libfoo.so
# (Only if libfoo.so.8 and libfoo.so exists on host system.)
rev_lib_symlinks() {
    [[ ! $1 ]] && return 0

    local fn="$1" orig="$(readlink -f "$1")" links=''

    [[ ${fn} == *.so.* ]] || return 1

    until [[ ${fn##*.} == so ]]; do
        fn="${fn%.*}"
        [[ -L ${fn} && $(readlink -f "${fn}") == ${orig} ]] && links+=" ${fn}"
    done

    echo "${links}"
}

# attempt to install any programs specified in a udev rule
inst_rule_programs() {
    local _prog _bin

    if grep -qE 'PROGRAM==?"[^ "]+' "$1"; then
        for _prog in $(grep -E 'PROGRAM==?"[^ "]+' "$1" | sed -r 's/.*PROGRAM==?"([^ "]+).*/\1/'); do
            _bin=""
            if [ -x ${udevdir}/$_prog ]; then
                _bin=${udevdir}/$_prog
            elif [[ "${_prog/\$env\{/}" == "$_prog" ]]; then
                _bin=$(find_binary "$_prog") || {
                    dinfo "Skipping program $_prog using in udev rule ${1##*/} as it cannot be found"
                    continue;
                }
            fi

            [[ $_bin ]] && inst_binary "$_bin"
        done
    fi
    if grep -qE 'RUN[+=]=?"[^ "]+' "$1"; then
        for _prog in $(grep -E 'RUN[+=]=?"[^ "]+' "$1" | sed -r 's/.*RUN[+=]=?"([^ "]+).*/\1/'); do
            _bin=""
            if [ -x ${udevdir}/$_prog ]; then
                _bin=${udevdir}/$_prog
            elif [[ "${_prog/\$env\{/}" == "$_prog" ]] && [[ "${_prog}" != "/sbin/initqueue" ]]; then
                _bin=$(find_binary "$_prog") || {
                    dinfo "Skipping program $_prog using in udev rule ${1##*/} as it cannot be found"
                    continue;
                }
            fi

            [[ $_bin ]] && inst_binary "$_bin"
        done
    fi
    if grep -qE 'IMPORT\{program\}==?"[^ "]+' "$1"; then
        for _prog in $(grep -E 'IMPORT\{program\}==?"[^ "]+' "$1" | sed -r 's/.*IMPORT\{program\}==?"([^ "]+).*/\1/'); do
            _bin=""
            if [ -x ${udevdir}/$_prog ]; then
                _bin=${udevdir}/$_prog
            elif [[ "${_prog/\$env\{/}" == "$_prog" ]]; then
                _bin=$(find_binary "$_prog") || {
                    dinfo "Skipping program $_prog using in udev rule ${1##*/} as it cannot be found"
                    continue;
                }
            fi

            [[ $_bin ]] && dracut_install "$_bin"
        done
    fi
}

# attempt to install any programs specified in a udev rule
inst_rule_group_owner() {
    local i

    if grep -qE 'OWNER=?"[^ "]+' "$1"; then
        for i in $(grep -E 'OWNER=?"[^ "]+' "$1" | sed -r 's/.*OWNER=?"([^ "]+).*/\1/'); do
            if ! egrep -q "^$i:" "$initdir/etc/passwd" 2>/dev/null; then
                egrep "^$i:" /etc/passwd 2>/dev/null >> "$initdir/etc/passwd"
            fi
        done
    fi
    if grep -qE 'GROUP=?"[^ "]+' "$1"; then
        for i in $(grep -E 'GROUP=?"[^ "]+' "$1" | sed -r 's/.*GROUP=?"([^ "]+).*/\1/'); do
            if ! egrep -q "^$i:" "$initdir/etc/group" 2>/dev/null; then
                egrep "^$i:" /etc/group 2>/dev/null >> "$initdir/etc/group"
            fi
        done
    fi
}

inst_rule_initqueue() {
    if grep -q -F initqueue "$1"; then
        dracut_need_initqueue
    fi
}

# udev rules always get installed in the same place, so
# create a function to install them to make life simpler.
inst_rules() {
    local _target=/etc/udev/rules.d _rule _found

    inst_dir "${udevdir}/rules.d"
    inst_dir "$_target"
    for _rule in "$@"; do
        if [ "${_rule#/}" = "$_rule" ]; then
            for r in ${udevdir}/rules.d ${hostonly:+/etc/udev/rules.d}; do
                [[ -e $r/$_rule ]] || continue
                _found="$r/$_rule"
                inst_rule_programs "$_found"
                inst_rule_group_owner "$_found"
                inst_rule_initqueue "$_found"
                inst_simple "$_found"
            done
        fi
        for r in '' $dracutbasedir/rules.d/; do
            # skip rules without an absolute path
            [[ "${r}$_rule" != /* ]] && continue
            [[ -f ${r}$_rule ]] || continue
            _found="${r}$_rule"
            inst_rule_programs "$_found"
            inst_rule_group_owner "$_found"
            inst_rule_initqueue "$_found"
            inst_simple "$_found" "$_target/${_found##*/}"
        done
        [[ $_found ]] || dinfo "Skipping udev rule: $_rule"
    done
}

inst_rules_wildcard() {
    local _target=/etc/udev/rules.d _rule _found

    inst_dir "${udevdir}/rules.d"
    inst_dir "$_target"
    for _rule in ${udevdir}/rules.d/$1 ${dracutbasedir}/rules.d/$1 ; do
        [[ -e $_rule ]] || continue
        inst_rule_programs "$_rule"
        inst_rule_group_owner "$_rule"
        inst_rule_initqueue "$_rule"
        inst_simple "$_rule"
        _found=$_rule
    done
    if [[ -n ${hostonly} ]] ; then
        for _rule in ${_target}/$1 ; do
            [[ -f $_rule ]] || continue
            inst_rule_programs "$_rule"
            inst_rule_group_owner "$_rule"
            inst_rule_initqueue "$_rule"
            inst_simple "$_rule"
            _found=$_rule
        done
    fi
    [[ $_found ]] || dinfo "Skipping udev rule: $_rule"
}

prepare_udev_rules() {
    [ -z "$UDEVVERSION" ] && export UDEVVERSION=$(udevadm --version)

    for f in "$@"; do
        f="${initdir}/etc/udev/rules.d/$f"
        [ -e "$f" ] || continue
        while read line || [ -n "$line" ]; do
            if [ "${line%%IMPORT PATH_ID}" != "$line" ]; then
                if [ $UDEVVERSION -ge 174 ]; then
                    printf '%sIMPORT{builtin}="path_id"\n' "${line%%IMPORT PATH_ID}"
                else
                    printf '%sIMPORT{program}="path_id %%p"\n' "${line%%IMPORT PATH_ID}"
                fi
            elif [ "${line%%IMPORT BLKID}" != "$line" ]; then
                if [ $UDEVVERSION -ge 176 ]; then
                    printf '%sIMPORT{builtin}="blkid"\n' "${line%%IMPORT BLKID}"
                else
                    printf '%sIMPORT{program}="/sbin/blkid -o udev -p $tempnode"\n' "${line%%IMPORT BLKID}"
                fi
            else
                echo "$line"
            fi
        done < "${f}" > "${f}.new"
        mv "${f}.new" "$f"
    done
}

# install function specialized for hooks
# $1 = type of hook, $2 = hook priority (lower runs first), $3 = hook
# All hooks should be POSIX/SuS compliant, they will be sourced by init.
inst_hook() {
    if ! [[ -f $3 ]]; then
        dfatal "Cannot install a hook ($3) that does not exist."
        dfatal "Aborting initrd creation."
        exit 1
    elif ! [[ "$hookdirs" == *$1* ]]; then
        dfatal "No such hook type $1. Aborting initrd creation."
        exit 1
    fi
    inst_simple "$3" "/lib/dracut/hooks/${1}/${2}-${3##*/}"
}

# install any of listed files
#
# If first argument is '-d' and second some destination path, first accessible
# source is installed into this path, otherwise it will installed in the same
# path as source.  If none of listed files was installed, function return 1.
# On first successful installation it returns with 0 status.
#
# Example:
#
# inst_any -d /bin/foo /bin/bar /bin/baz
#
# Lets assume that /bin/baz exists, so it will be installed as /bin/foo in
# initramfs.
inst_any() {
    local to f

    [[ $1 = '-d' ]] && to="$2" && shift 2

    for f in "$@"; do
        [[ -e $f ]] || continue
        [[ $to ]] && inst "$f" "$to" && return 0
        inst "$f" && return 0
    done

    return 1
}


# inst_libdir_file [-n <pattern>] <file> [<file>...]
# Install a <file> located on a lib directory to the initramfs image
# -n <pattern> install matching files
inst_libdir_file() {
    local _files
    if [[ "$1" == "-n" ]]; then
        local _pattern=$2
        shift 2
        for _dir in $libdirs; do
            for _i in "$@"; do
                for _f in "$_dir"/$_i; do
                    [[ "$_f" =~ $_pattern ]] || continue
                    [[ -e "$_f" ]] && _files+="$_f "
                done
            done
        done
    else
        for _dir in $libdirs; do
            for _i in "$@"; do
                for _f in "$_dir"/$_i; do
                    [[ -e "$_f" ]] && _files+="$_f "
                done
            done
        done
    fi
    [[ $_files ]] && inst_multiple $_files
}


# install function decompressing the target and handling symlinks
# $@ = list of compressed (gz or bz2) files or symlinks pointing to such files
#
# Function install targets in the same paths inside overlay but decompressed
# and without extensions (.gz, .bz2).
inst_decompress() {
    local _src _cmd

    for _src in $@
    do
        case ${_src} in
            *.gz) _cmd='gzip -f -d' ;;
            *.bz2) _cmd='bzip2 -d' ;;
            *) return 1 ;;
        esac
        inst_simple ${_src}
        # Decompress with chosen tool.  We assume that tool changes name e.g.
        # from 'name.gz' to 'name'.
        ${_cmd} "${initdir}${_src}"
    done
}

# It's similar to above, but if file is not compressed, performs standard
# install.
# $@ = list of files
inst_opt_decompress() {
    local _src

    for _src in $@; do
        inst_decompress "${_src}" || inst "${_src}"
    done
}

# module_check <dracut module>
# execute the check() function of module-setup.sh of <dracut module>
# or the "check" script, if module-setup.sh is not found
# "check $hostonly" is called
module_check() {
    local _moddir=$(echo ${dracutbasedir}/modules.d/??${1} | { read a b; echo "$a"; })
    local _ret
    local _forced=0
    local _hostonly=$hostonly
    [ $# -eq 2 ] && _forced=$2
    [[ -d $_moddir ]] || return 1
    if [[ ! -f $_moddir/module-setup.sh ]]; then
        # if we do not have a check script, we are unconditionally included
        [[ -x $_moddir/check ]] || return 0
        [ $_forced -ne 0 ] && unset hostonly
        $_moddir/check $hostonly
        _ret=$?
    else
        unset check depends cmdline install installkernel
        check() { true; }
        . $_moddir/module-setup.sh
        is_func check || return 0
        [ $_forced -ne 0 ] && unset hostonly
        moddir=$_moddir check $hostonly
        _ret=$?
        unset check depends cmdline install installkernel
    fi
    hostonly=$_hostonly
    return $_ret
}

# module_check_mount <dracut module>
# execute the check() function of module-setup.sh of <dracut module>
# or the "check" script, if module-setup.sh is not found
# "mount_needs=1 check 0" is called
module_check_mount() {
    local _moddir=$(echo ${dracutbasedir}/modules.d/??${1} | { read a b; echo "$a"; })
    local _ret
    mount_needs=1
    [[ -d $_moddir ]] || return 1
    if [[ ! -f $_moddir/module-setup.sh ]]; then
        # if we do not have a check script, we are unconditionally included
        [[ -x $_moddir/check ]] || return 0
        mount_needs=1 $_moddir/check 0
        _ret=$?
    else
        unset check depends cmdline install installkernel
        check() { false; }
        . $_moddir/module-setup.sh
        moddir=$_moddir check 0
        _ret=$?
        unset check depends cmdline install installkernel
    fi
    unset mount_needs
    return $_ret
}

# module_depends <dracut module>
# execute the depends() function of module-setup.sh of <dracut module>
# or the "depends" script, if module-setup.sh is not found
module_depends() {
    local _moddir=$(echo ${dracutbasedir}/modules.d/??${1} | { read a b; echo "$a"; })
    local _ret
    [[ -d $_moddir ]] || return 1
    if [[ ! -f $_moddir/module-setup.sh ]]; then
        # if we do not have a check script, we have no deps
        [[ -x $_moddir/check ]] || return 0
        $_moddir/check -d
        return $?
    else
        unset check depends cmdline install installkernel
        depends() { true; }
        . $_moddir/module-setup.sh
        moddir=$_moddir depends
        _ret=$?
        unset check depends cmdline install installkernel
        return $_ret
    fi
}

# module_cmdline <dracut module>
# execute the cmdline() function of module-setup.sh of <dracut module>
# or the "cmdline" script, if module-setup.sh is not found
module_cmdline() {
    local _moddir=$(echo ${dracutbasedir}/modules.d/??${1} | { read a b; echo "$a"; })
    local _ret
    [[ -d $_moddir ]] || return 1
    if [[ ! -f $_moddir/module-setup.sh ]]; then
        [[ -x $_moddir/cmdline ]] && . "$_moddir/cmdline"
        return $?
    else
        unset check depends cmdline install installkernel
        cmdline() { true; }
        . $_moddir/module-setup.sh
        moddir=$_moddir cmdline
        _ret=$?
        unset check depends cmdline install installkernel
        return $_ret
    fi
}

# module_install <dracut module>
# execute the install() function of module-setup.sh of <dracut module>
# or the "install" script, if module-setup.sh is not found
module_install() {
    local _moddir=$(echo ${dracutbasedir}/modules.d/??${1} | { read a b; echo "$a"; })
    local _ret
    [[ -d $_moddir ]] || return 1
    if [[ ! -f $_moddir/module-setup.sh ]]; then
        [[ -x $_moddir/install ]] && . "$_moddir/install"
        return $?
    else
        unset check depends cmdline install installkernel
        install() { true; }
        . $_moddir/module-setup.sh
        moddir=$_moddir install
        _ret=$?
        unset check depends cmdline install installkernel
        return $_ret
    fi
}

# module_installkernel <dracut module>
# execute the installkernel() function of module-setup.sh of <dracut module>
# or the "installkernel" script, if module-setup.sh is not found
module_installkernel() {
    local _moddir=$(echo ${dracutbasedir}/modules.d/??${1} | { read a b; echo "$a"; })
    local _ret
    [[ -d $_moddir ]] || return 1
    if [[ ! -f $_moddir/module-setup.sh ]]; then
        [[ -x $_moddir/installkernel ]] && . "$_moddir/installkernel"
        return $?
    else
        unset check depends cmdline install installkernel
        installkernel() { true; }
        . $_moddir/module-setup.sh
        moddir=$_moddir installkernel
        _ret=$?
        unset check depends cmdline install installkernel
        return $_ret
    fi
}

# check_mount <dracut module>
# check_mount checks, if a dracut module is needed for the given
# device and filesystem types in "${host_fs_types[@]}"
check_mount() {
    local _mod=$1
    local _moddir=$(echo ${dracutbasedir}/modules.d/??${1} | { read a b; echo "$a"; })
    local _ret
    local _moddep

    [ "${#host_fs_types[@]}" -le 0 ] && return 1

    # If we are already scheduled to be loaded, no need to check again.
    [[ " $mods_to_load " == *\ $_mod\ * ]] && return 0
    [[ " $mods_checked_as_dep " == *\ $_mod\ * ]] && return 1

    # This should never happen, but...
    [[ -d $_moddir ]] || return 1

    [[ $2 ]] || mods_checked_as_dep+=" $_mod "

    if [[ " $omit_dracutmodules " == *\ $_mod\ * ]]; then
        return 1
    fi

    if [[ " $dracutmodules $add_dracutmodules $force_add_dracutmodules" == *\ $_mod\ * ]]; then
        module_check_mount $_mod; ret=$?

        # explicit module, so also accept ret=255
        [[ $ret = 0 || $ret = 255 ]] || return 1
    else
        # module not in our list
        if [[ $dracutmodules = all ]]; then
            # check, if we can and should install this module
            module_check_mount $_mod || return 1
        else
            # skip this module
            return 1
        fi
    fi

    for _moddep in $(module_depends $_mod); do
        # handle deps as if they were manually added
        [[ " $dracutmodules " == *\ $_mod\ * ]] \
            && [[ " $dracutmodules " != *\ $_moddep\ * ]] \
            && dracutmodules+=" $_moddep "
        [[ " $add_dracutmodules " == *\ $_mod\ * ]] \
            && [[ " $add_dracutmodules " != *\ $_moddep\ * ]] \
            && add_dracutmodules+=" $_moddep "
        [[ " $force_add_dracutmodules " == *\ $_mod\ * ]] \
            && [[ " $force_add_dracutmodules " != *\ $_moddep\ * ]] \
            && force_add_dracutmodules+=" $_moddep "
        # if a module we depend on fail, fail also
        if ! check_module $_moddep; then
            derror "dracut module '$_mod' depends on '$_moddep', which can't be installed"
            return 1
        fi
    done

    [[ " $mods_to_load " == *\ $_mod\ * ]] || \
        mods_to_load+=" $_mod "

    return 0
}

# check_module <dracut module> [<use_as_dep>]
# check if a dracut module is to be used in the initramfs process
# if <use_as_dep> is set, then the process also keeps track
# that the modules were checked for the dependency tracking process
check_module() {
    local _mod=$1
    local _moddir=$(echo ${dracutbasedir}/modules.d/??${1} | { read a b; echo "$a"; })
    local _ret
    local _moddep
    # If we are already scheduled to be loaded, no need to check again.
    [[ " $mods_to_load " == *\ $_mod\ * ]] && return 0
    [[ " $mods_checked_as_dep " == *\ $_mod\ * ]] && return 1

    # This should never happen, but...
    [[ -d $_moddir ]] || return 1

    [[ $2 ]] || mods_checked_as_dep+=" $_mod "

    if [[ " $omit_dracutmodules " == *\ $_mod\ * ]]; then
        dinfo "dracut module '$_mod' will not be installed, because it's in the list to be omitted!"
        return 1
    fi

    if [[ " $dracutmodules $add_dracutmodules $force_add_dracutmodules" == *\ $_mod\ * ]]; then
        if [[ " $dracutmodules $force_add_dracutmodules " == *\ $_mod\ * ]]; then
            module_check $_mod 1; ret=$?
        else
            module_check $_mod 0; ret=$?
        fi
        # explicit module, so also accept ret=255
        [[ $ret = 0 || $ret = 255 ]] || return 1
    else
        # module not in our list
        if [[ $dracutmodules = all ]]; then
            # check, if we can and should install this module
            module_check $_mod; ret=$?
            if [[ $ret != 0 ]]; then
                [[ $2 ]] && return 1
                [[ $ret != 255 ]] && return 1
            fi
        else
            # skip this module
            return 1
        fi
    fi

    for _moddep in $(module_depends $_mod); do
        # handle deps as if they were manually added
        [[ " $dracutmodules " == *\ $_mod\ * ]] \
            && [[ " $dracutmodules " != *\ $_moddep\ * ]] \
            && dracutmodules+=" $_moddep "
        [[ " $add_dracutmodules " == *\ $_mod\ * ]] \
            && [[ " $add_dracutmodules " != *\ $_moddep\ * ]] \
            && add_dracutmodules+=" $_moddep "
        [[ " $force_add_dracutmodules " == *\ $_mod\ * ]] \
            && [[ " $force_add_dracutmodules " != *\ $_moddep\ * ]] \
            && force_add_dracutmodules+=" $_moddep "
        # if a module we depend on fail, fail also
        if ! check_module $_moddep; then
            derror "dracut module '$_mod' depends on '$_moddep', which can't be installed"
            return 1
        fi
    done

    [[ " $mods_to_load " == *\ $_mod\ * ]] || \
        mods_to_load+=" $_mod "

    return 0
}

# for_each_module_dir <func>
# execute "<func> <dracut module> 1"
for_each_module_dir() {
    local _modcheck
    local _mod
    local _moddir
    local _func
    _func=$1
    for _moddir in "$dracutbasedir/modules.d"/[0-9][0-9]*; do
        [[ -d $_moddir ]] || continue;
        [[ -e $_moddir/install || -e $_moddir/installkernel || \
            -e $_moddir/module-setup.sh ]] || continue
        _mod=${_moddir##*/}; _mod=${_mod#[0-9][0-9]}
        $_func $_mod 1
    done

    # Report any missing dracut modules, the user has specified
    _modcheck="$add_dracutmodules $force_add_dracutmodules"
    [[ $dracutmodules != all ]] && _modcheck="$_modcheck $dracutmodules"
    for _mod in $_modcheck; do
        [[ " $mods_to_load " == *\ $_mod\ * ]] && continue

        [[ " $force_add_dracutmodules " != *\ $_mod\ * ]] \
            && [[ " $dracutmodules " != *\ $_mod\ * ]] \
            && [[ " $omit_dracutmodules " == *\ $_mod\ * ]] \
            && continue

        derror "dracut module '$_mod' cannot be found or installed."
        [[ " $force_add_dracutmodules " == *\ $_mod\ * ]] && exit 1
        [[ " $dracutmodules " == *\ $_mod\ * ]] && exit 1
        [[ " $add_dracutmodules " == *\ $_mod\ * ]] && exit 1
    done
}

# Install a single kernel module along with any firmware it may require.
# $1 = full path to kernel module to install
install_kmod_with_fw() {
    # no need to go further if the module is already installed

    [[ -e "${initdir}/lib/modules/$kernel/${1##*/lib/modules/$kernel/}" ]] \
        && return 0

    if [[ $DRACUT_KERNEL_LAZY_HASHDIR ]] && [[ -e "$DRACUT_KERNEL_LAZY_HASHDIR/${1##*/}" ]]; then
        read ret < "$DRACUT_KERNEL_LAZY_HASHDIR/${1##*/}"
        return $ret
    fi

    if [[ $omit_drivers ]]; then
        local _kmod=${1##*/}
        _kmod=${_kmod%.ko*}
        _kmod=${_kmod/-/_}
        if [[ "$_kmod" =~ $omit_drivers ]]; then
            dinfo "Omitting driver $_kmod"
            return 0
        fi
        if [[ "${1##*/lib/modules/$kernel/}" =~ $omit_drivers ]]; then
            dinfo "Omitting driver $_kmod"
            return 0
        fi
    fi

    if [[ $silent_omit_drivers ]]; then
        local _kmod=${1##*/}
        _kmod=${_kmod%.ko*}
        _kmod=${_kmod/-/_}
        [[ "$_kmod" =~ $silent_omit_drivers ]] && return 0
        [[ "${1##*/lib/modules/$kernel/}" =~ $silent_omit_drivers ]] && return 0
    fi

    inst_simple "$1" "/lib/modules/$kernel/${1##*/lib/modules/$kernel/}"
    ret=$?
    [[ $DRACUT_KERNEL_LAZY_HASHDIR ]] && \
        [[ -d "$DRACUT_KERNEL_LAZY_HASHDIR" ]] && \
        echo $ret > "$DRACUT_KERNEL_LAZY_HASHDIR/${1##*/}"
    (($ret != 0)) && return $ret

    local _modname=${1##*/} _fwdir _found _fw
    _modname=${_modname%.ko*}
    for _fw in $(modinfo -k $kernel -F firmware $1 2>/dev/null); do
        _found=''
        for _fwdir in $fw_dir; do
            [[ -d $_fwdir && -f $_fwdir/$_fw ]] || continue
            inst_simple "$_fwdir/$_fw" "/lib/firmware/$_fw"
            _found=yes
        done
        if [[ $_found != yes ]]; then
            if ! [[ -d $(echo /sys/module/${_modname//-/_}|{ read a b; echo $a; }) ]]; then
                dinfo "Possible missing firmware \"${_fw}\" for kernel module" \
                    "\"${_modname}.ko\""
            else
                dwarn "Possible missing firmware \"${_fw}\" for kernel module" \
                    "\"${_modname}.ko\""
            fi
        fi
    done
    return 0
}

# Do something with all the dependencies of a kernel module.
# Note that kernel modules depend on themselves using the technique we use
# $1 = function to call for each dependency we find
#      It will be passed the full path to the found kernel module
# $2 = module to get dependencies for
# rest of args = arguments to modprobe
# _fderr specifies FD passed from surrounding scope
for_each_kmod_dep() {
    local _func=$1 _kmod=$2 _cmd _modpath _options
    shift 2
    modprobe "$@" --ignore-install --show-depends $_kmod 2>&${_fderr} | (
        while read _cmd _modpath _options || [ -n "$_cmd" ]; do
            [[ $_cmd = insmod ]] || continue
            $_func ${_modpath} || exit $?
        done
    )
}

dracut_kernel_post() {
    local _moddirname=${srcmods%%/lib/modules/*}
    local _pid

    if [[ $DRACUT_KERNEL_LAZY_HASHDIR ]] && [[ -f "$DRACUT_KERNEL_LAZY_HASHDIR/lazylist" ]]; then
        xargs -r modprobe -a ${_moddirname:+-d ${_moddirname}/} \
            --ignore-install --show-depends --set-version $kernel \
            < "$DRACUT_KERNEL_LAZY_HASHDIR/lazylist" 2>/dev/null \
            | sort -u \
            | while read _cmd _modpath _options || [ -n "$_cmd" ]; do
            [[ $_cmd = insmod ]] || continue
            echo "$_modpath"
        done > "$DRACUT_KERNEL_LAZY_HASHDIR/lazylist.dep"

        (
            if [[ $DRACUT_INSTALL ]] && [[ -z $_moddirname ]]; then
                xargs -r $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} -a < "$DRACUT_KERNEL_LAZY_HASHDIR/lazylist.dep"
            else
                while read _modpath || [ -n "$_modpath" ]; do
                    local _destpath=$_modpath
                    [[ $_moddirname ]] && _destpath=${_destpath##$_moddirname/}
                    _destpath=${_destpath##*/lib/modules/$kernel/}
                    inst_simple "$_modpath" "/lib/modules/$kernel/${_destpath}" || exit $?
                done < "$DRACUT_KERNEL_LAZY_HASHDIR/lazylist.dep"
            fi
        ) &
        _pid=$(jobs -p | while read a  || [ -n "$a" ]; do printf ":$a";done)
        _pid=${_pid##*:}

        if [[ $DRACUT_INSTALL ]]; then
            xargs -r modinfo -k $kernel -F firmware < "$DRACUT_KERNEL_LAZY_HASHDIR/lazylist.dep" \
                | while read line || [ -n "$line" ]; do
                for _fwdir in $fw_dir; do
                    echo $_fwdir/$line;
                done;
            done | xargs -r $DRACUT_INSTALL ${initdir:+-D "$initdir"} ${loginstall:+-L "$loginstall"} -a -o
        else
            for _fw in $(xargs -r modinfo -k $kernel -F firmware < "$DRACUT_KERNEL_LAZY_HASHDIR/lazylist.dep"); do
                for _fwdir in $fw_dir; do
                    [[ -d $_fwdir && -f $_fwdir/$_fw ]] || continue
                    inst_simple "$_fwdir/$_fw" "/lib/firmware/$_fw"
                    break
                done
            done
        fi

        wait $_pid
    fi

    for _f in modules.builtin.bin modules.builtin modules.order; do
        [[ $srcmods/$_f ]] && inst_simple "$srcmods/$_f" "/lib/modules/$kernel/$_f"
    done

    # generate module dependencies for the initrd
    if [[ -d $initdir/lib/modules/$kernel ]] && \
        ! depmod -a -b "$initdir" $kernel; then
        dfatal "\"depmod -a $kernel\" failed."
        exit 1
    fi

    [[ $DRACUT_KERNEL_LAZY_HASHDIR ]] && rm -fr -- "$DRACUT_KERNEL_LAZY_HASHDIR"
}

[[ "$kernel_current" ]] || export kernel_current=$(uname -r)

module_is_host_only() {
    local _mod=$1
    local _modenc a i _k _s _v _aliases
    _mod=${_mod##*/}
    _mod=${_mod%.ko*}
    _modenc=${_mod//-/_}

    [[ " $add_drivers " == *\ ${_mod}\ * ]] && return 0

    # check if module is loaded
    [[ ${host_modules["$_modenc"]} ]] && return 0

    [[ "$kernel_current" ]] || export kernel_current=$(uname -r)

    if [[ "$kernel_current" != "$kernel" ]]; then
        # check if module is loadable on the current kernel
        # this covers the case, where a new module is introduced
        # or a module was renamed
        # or a module changed from builtin to a module

        if [[ -d /lib/modules/$kernel_current ]]; then
            # if the modinfo can be parsed, but the module
            # is not loaded, then we can safely return 1
            modinfo -F filename "$_mod" &>/dev/null && return 1
        fi

        # just install the module, better safe than sorry
        return 0
    fi

    return 1
}

find_kernel_modules_by_path () {
    local _OLDIFS

    [[ -f "$srcmods/modules.dep" ]] || return 0

    _OLDIFS=$IFS
    IFS=:
    while read a rest || [ -n "$a" ]; do
        [[ $a = */$1/* ]] || [[ $a = updates/* ]] || continue
        printf "%s\n" "$srcmods/$a"
    done < "$srcmods/modules.dep"
    IFS=$_OLDIFS
    return 0
}

find_kernel_modules () {
    find_kernel_modules_by_path  drivers
}

# instmods [-c [-s]] <kernel module> [<kernel module> ... ]
# instmods [-c [-s]] <kernel subsystem>
# install kernel modules along with all their dependencies.
# <kernel subsystem> can be e.g. "=block" or "=drivers/usb/storage"
instmods() {
    [[ $no_kernel = yes ]] && return
    # called [sub]functions inherit _fderr
    local _fderr=9
    local _check=no
    local _silent=no
    if [[ $1 = '-c' ]]; then
        _check=yes
        shift
    fi

    if [[ $1 = '-s' ]]; then
        _silent=yes
        shift
    fi

    function inst1mod() {
        local _ret=0 _mod="$1"
        case $_mod in
            =*)
                ( [[ "$_mpargs" ]] && echo $_mpargs
                    find_kernel_modules_by_path "${_mod#=}" ) \
                        | instmods
                ((_ret+=$?))
                ;;
            --*) _mpargs+=" $_mod" ;;
            *)
                _mod=${_mod##*/}
                # Check for aliased modules
                _modalias=$(modinfo -k $kernel -F filename $_mod 2> /dev/null)
                _modalias=${_modalias%.ko*}
                if [[ $_modalias ]] && [ "${_modalias##*/}" != "${_mod%.ko*}" ] ; then
                    _mod=${_modalias##*/}
                fi

                # if we are already installed, skip this module and go on
                # to the next one.
                if [[ $DRACUT_KERNEL_LAZY_HASHDIR ]] && \
                    [[ -f "$DRACUT_KERNEL_LAZY_HASHDIR/${_mod%.ko*}" ]]; then
                    read _ret <"$DRACUT_KERNEL_LAZY_HASHDIR/${_mod%.ko*}"
                    return $_ret
                fi

                _mod=${_mod/-/_}
                if [[ $omit_drivers ]] && [[ "$_mod" =~ $omit_drivers ]]; then
                    dinfo "Omitting driver ${_mod##$srcmods}"
                    return 0
                fi

                # If we are building a host-specific initramfs and this
                # module is not already loaded, move on to the next one.
                [[ $hostonly ]] \
                    && ! module_is_host_only "$_mod" \
                    && return 0

                if [[ "$_check" = "yes" ]] || ! [[ $DRACUT_KERNEL_LAZY_HASHDIR ]]; then
                    # We use '-d' option in modprobe only if modules prefix path
                    # differs from default '/'.  This allows us to use dracut with
                    # old version of modprobe which doesn't have '-d' option.
                    local _moddirname=${srcmods%%/lib/modules/*}
                    [[ -n ${_moddirname} ]] && _moddirname="-d ${_moddirname}/"

                    # ok, load the module, all its dependencies, and any firmware
                    # it may require
                    for_each_kmod_dep install_kmod_with_fw $_mod \
                        --set-version $kernel ${_moddirname} $_mpargs
                    ((_ret+=$?))
                else
                    [[ $DRACUT_KERNEL_LAZY_HASHDIR ]] && \
                        echo ${_mod%.ko*} >> "$DRACUT_KERNEL_LAZY_HASHDIR/lazylist"
                fi
                ;;
        esac
        return $_ret
    }

    function instmods_1() {
        local _mod _mpargs
        if (($# == 0)); then  # filenames from stdin
            while read _mod || [ -n "$_mod" ]; do
                inst1mod "${_mod%.ko*}" || {
                    if [[ "$_check" == "yes" ]] && [[ "$_silent" == "no" ]]; then
                        dfatal "Failed to install module $_mod"
                    fi
                }
            done
        fi
        while (($# > 0)); do  # filenames as arguments
            inst1mod ${1%.ko*} || {
                if [[ "$_check" == "yes" ]] && [[ "$_silent" == "no" ]]; then
                    dfatal "Failed to install module $1"
                fi
            }
            shift
        done
        return 0
    }

    local _ret _filter_not_found='FATAL: Module .* not found.'
    # Capture all stderr from modprobe to _fderr. We could use {var}>...
    # redirections, but that would make dracut require bash4 at least.
    eval "( instmods_1 \"\$@\" ) ${_fderr}>&1" \
        | while read line || [ -n "$line" ]; do [[ "$line" =~ $_filter_not_found ]] || echo $line;done | derror
    _ret=$?
    return $_ret
}
