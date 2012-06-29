#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Generator script for a dracut initramfs
# Tries to retain some degree of compatibility with the command line
# of the various mkinitrd implementations out there
#

# Copyright 2005-2010 Red Hat, Inc.  All rights reserved.
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

# store for logging
dracut_args="$@"

set -o pipefail

usage() {
    [[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut
    if [[ -f $dracutbasedir/dracut-version.sh ]]; then
        . $dracutbasedir/dracut-version.sh
    fi

#                                                       80x25 linebreak here ^
    cat << EOF
Usage: $0 [OPTION]... <initramfs> <kernel-version>

Version: $DRACUT_VERSION

Creates initial ramdisk images for preloading modules

  -f, --force           Overwrite existing initramfs file.
  -m, --modules [LIST]  Specify a space-separated list of dracut modules to
                         call when building the initramfs. Modules are located
                         in /usr/lib/dracut/modules.d.
  -o, --omit [LIST]     Omit a space-separated list of dracut modules.
  -a, --add [LIST]      Add a space-separated list of dracut modules.
  -d, --drivers [LIST]  Specify a space-separated list of kernel modules to
                        exclusively include in the initramfs.
  --add-drivers [LIST] Specify a space-separated list of kernel
                        modules to add to the initramfs.
  --omit-drivers [LIST] Specify a space-separated list of kernel
                        modules not to add to the initramfs.
  --filesystems [LIST]  Specify a space-separated list of kernel filesystem
                        modules to exclusively include in the generic
                        initramfs.
  -k, --kmoddir [DIR]   Specify the directory, where to look for kernel
                        modules
  --fwdir [DIR]         Specify additional directories, where to look for
                        firmwares, separated by :
  --kernel-only         Only install kernel drivers and firmware files
  --no-kernel           Do not install kernel drivers and firmware files
  --strip               Strip binaries in the initramfs
  --nostrip             Do not strip binaries in the initramfs (default)
  --prefix [DIR]        Prefix initramfs files with [DIR]
  --noprefix            Do not prefix initramfs files (default)
  --mdadmconf           Include local /etc/mdadm.conf
  --nomdadmconf         Do not include local /etc/mdadm.conf
  --lvmconf             Include local /etc/lvm/lvm.conf
  --nolvmconf           Do not include local /etc/lvm/lvm.conf
  --fscks [LIST]        Add a space-separated list of fsck helpers.
  --nofscks             Inhibit installation of any fsck helpers.
  -h, --help            This message
  --debug               Output debug information of the build process
  --profile             Output profile information of the build process
  -L, --stdlog [0-6]    Specify logging level (to standard error)
                         0 - suppress any messages
                         1 - only fatal errors
                         2 - all errors
                         3 - warnings
                         4 - info (default)
                         5 - debug info (here starts lots of output)
                         6 - trace info (and even more)
  -v, --verbose         Increase verbosity level (default is info(4))
  -q, --quiet           Decrease verbosity level (default is info(4))
  -c, --conf [FILE]     Specify configuration file to use.
                         Default: /etc/dracut.conf
  --confdir [DIR]       Specify configuration directory to use *.conf files
                         from. Default: /etc/dracut.conf.d
  --tmpdir [DIR]        Temporary directory to be used instead of default
                         /var/tmp.
  -l, --local           Local mode. Use modules from the current working
                         directory instead of the system-wide installed in
                         /usr/lib/dracut/modules.d.
                         Useful when running dracut from a git checkout.
  -H, --hostonly        Host-Only mode: Install only what is needed for
                         booting the local host instead of a generic host.
  --no-hostonly         Disables Host-Only mode
  --fstab               Use /etc/fstab to determine the root device.
  --add-fstab [FILE]    Add file to the initramfs fstab
  --mount "[DEV] [MP] [FSTYPE] [FSOPTS]"
                        Mount device [DEV] on mountpoint [MP] with filesystem
                        [FSTYPE] and options [FSOPTS] in the initramfs
  -i, --include [SOURCE] [TARGET]
                        Include the files in the SOURCE directory into the
                         Target directory in the final initramfs.
                        If SOURCE is a file, it will be installed to TARGET
                         in the final initramfs.
  -I, --install [LIST]  Install the space separated list of files into the
                         initramfs.
  --gzip                Compress the generated initramfs using gzip.
                         This will be done by default, unless another
                         compression option or --no-compress is passed.
  --bzip2               Compress the generated initramfs using bzip2.
                         Make sure your kernel has bzip2 decompression support
                         compiled in, otherwise you will not be able to boot.
  --lzma                Compress the generated initramfs using lzma.
                         Make sure your kernel has lzma support compiled in,
                         otherwise you will not be able to boot.
  --xz                  Compress the generated initramfs using xz.
                         Make sure that your kernel has xz support compiled
                         in, otherwise you will not be able to boot.
  --compress [COMPRESSION] Compress the generated initramfs with the
                         passed compression program.  Make sure your kernel
                         knows how to decompress the generated initramfs,
                         otherwise you will not be able to boot.
  --no-compress         Do not compress the generated initramfs.  This will
                         override any other compression options.
  --list-modules        List all available dracut modules.
  -M, --show-modules    Print included module's name to standard output during
                         build.
  --keep                Keep the temporary initramfs for debugging purposes
  --printsize           Print out the module install size
  --sshkey [SSHKEY]     Add ssh key to initramfs (use with ssh-client module)

If [LIST] has multiple arguments, then you have to put these in quotes.
For example:
# dracut --add-drivers "module1 module2"  ...
EOF
}

# function push()
# push values to a stack
# $1 = stack variable
# $2.. values
# example:
# push stack 1 2 "3 4"
push() {
    local __stack=$1; shift
    for i in "$@"; do
        eval ${__stack}'[${#'${__stack}'[@]}]="$i"'
    done
}

# function pop()
# pops the last value from a stack
# assigns value to second argument variable
# or echo to stdout, if no second argument
# $1 = stack variable
# $2 = optional variable to store the value
# example:
# pop stack val
# val=$(pop stack)
pop() {
    local __stack=$1; shift
    local __resultvar=$1
    local myresult;
    # check for empty stack
    eval '[[ ${#'${__stack}'[@]} -eq 0 ]] && return 1'

    eval myresult='${'${__stack}'[${#'${__stack}'[@]}-1]}'

    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$myresult'"
    else
        echo "$myresult"
    fi
    eval unset ${__stack}'[${#'${__stack}'[@]}-1]'
    return 0
}

# Little helper function for reading args from the commandline.
# it automatically handles -a b and -a=b variants, and returns 1 if
# we need to shift $3.
read_arg() {
    # $1 = arg name
    # $2 = arg value
    # $3 = arg parameter
    local rematch='^[^=]*=(.*)$'
    if [[ $2 =~ $rematch ]]; then
        read "$1" <<< "${BASH_REMATCH[1]}"
    else
        read "$1" <<< "$3"
        # There is no way to shift our callers args, so
        # return 1 to indicate they should do it instead.
        return 1
    fi
}

# Little helper function for reading args from the commandline to a stack.
# it automatically handles -a b and -a=b variants, and returns 1 if
# we need to shift $3.
push_arg() {
    # $1 = arg name
    # $2 = arg value
    # $3 = arg parameter
    local rematch='^[^=]*=(.*)$'
    if [[ $2 =~ $rematch ]]; then
        push "$1" "${BASH_REMATCH[1]}"
    else
        push "$1" "$3"
        # There is no way to shift our callers args, so
        # return 1 to indicate they should do it instead.
        return 1
    fi
}

verbosity_mod_l=0
unset kernel
unset outfile

while (($# > 0)); do
    case ${1%%=*} in
        -a|--add)      push_arg add_dracutmodules_l  "$@" || shift;;
        --force-add)   push_arg force_add_dracutmodules_l  "$@" || shift;;
        --add-drivers) push_arg add_drivers_l        "$@" || shift;;
        --omit-drivers) push_arg omit_drivers_l      "$@" || shift;;
        -m|--modules)  push_arg dracutmodules_l      "$@" || shift;;
        -o|--omit)     push_arg omit_dracutmodules_l "$@" || shift;;
        -d|--drivers)  push_arg drivers_l            "$@" || shift;;
        --filesystems) push_arg filesystems_l        "$@" || shift;;
        -I|--install)  push_arg install_items_l      "$@" || shift;;
        --fwdir)       push_arg fw_dir_l             "$@" || shift;;
        --libdirs)     push_arg libdirs_l            "$@" || shift;;
        --fscks)       push_arg fscks_l              "$@" || shift;;
        --add-fstab)   push_arg add_fstab_l          "$@" || shift;;
        --mount)       push_arg fstab_lines          "$@" || shift;;
        --nofscks)     nofscks_l="yes";;
        -k|--kmoddir)  read_arg drivers_dir_l        "$@" || shift;;
        -c|--conf)     read_arg conffile             "$@" || shift;;
        --confdir)     read_arg confdir              "$@" || shift;;
        --tmpdir)      read_arg tmpdir_l             "$@" || shift;;
        -L|--stdlog)   read_arg stdloglvl_l          "$@" || shift;;
        --compress)    read_arg compress_l           "$@" || shift;;
        --prefix)      read_arg prefix_l             "$@" || shift;;
        -f|--force)    force=yes;;
        --kernel-only) kernel_only="yes"; no_kernel="no";;
        --no-kernel)   kernel_only="no"; no_kernel="yes";;
        --strip)       do_strip_l="yes";;
        --nostrip)     do_strip_l="no";;
        --noprefix)    prefix_l="/";;
        --mdadmconf)   mdadmconf_l="yes";;
        --nomdadmconf) mdadmconf_l="no";;
        --lvmconf)     lvmconf_l="yes";;
        --nolvmconf)   lvmconf_l="no";;
        --debug)       debug="yes";;
        --profile)     profile="yes";;
        --sshkey)      read_arg sshkey   "$@" || shift;;
        -v|--verbose)  ((verbosity_mod_l++));;
        -q|--quiet)    ((verbosity_mod_l--));;
        -l|--local)
                       allowlocal="yes"
                       [[ -f "$(readlink -f ${0%/*})/dracut-functions.sh" ]] \
                           && dracutbasedir="$(readlink -f ${0%/*})"
                       ;;
        -H|--hostonly) hostonly_l="yes" ;;
        --no-hostonly) hostonly_l="no" ;;
        --fstab)       use_fstab_l="yes" ;;
        -h|--help)     usage; exit 1 ;;
        -i|--include)  push include_src "$2"
                       push include_target "$3"
                       shift 2;;
        --bzip2)       compress_l="bzip2";;
        --lzma)        compress_l="lzma";;
        --xz)          compress_l="xz";;
        --no-compress) _no_compress_l="cat";;
        --gzip)        compress_l="gzip";;
        --list-modules)
            do_list="yes";
            ;;
        -M|--show-modules)
                       show_modules_l="yes"
                       ;;
        --keep)        keep="yes";;
        --printsize)   printsize="yes";;
        -*) printf "\nUnknown option: %s\n\n" "$1" >&2; usage; exit 1;;
        *)
            if ! [[ ${outfile+x} ]]; then
                outfile=$1
            elif ! [[ ${kernel+x} ]]; then
                kernel=$1
            else
                echo "Unknown argument: $1"
                usage; exit 1;
            fi
            ;;
    esac
    shift
done
if ! [[ $kernel ]]; then
    kernel=$(uname -r)
fi
[[ $outfile ]] || outfile="/boot/initramfs-$kernel.img"

for i in /usr/sbin /sbin /usr/bin /bin; do
    rl=$i
    if [ -L "$i" ]; then
        rl=$(readlink -f $i)
    fi
    NPATH+=":$rl"
done
export PATH="${NPATH#:}"
unset NPATH
unset LD_LIBRARY_PATH
unset GREP_OPTIONS

export DRACUT_LOG_LEVEL=warning
[[ $debug ]] && {
    export DRACUT_LOG_LEVEL=debug
    export PS4='${BASH_SOURCE}@${LINENO}(${FUNCNAME[0]}): ';
    set -x
}

[[ $profile ]] && {
    export PS4='+ $(date "+%s.%N") ${BASH_SOURCE}@${LINENO}: ';
    set -x
    debug=yes
}

[[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut

# if we were not passed a config file, try the default one
if [[ ! -f $conffile ]]; then
    [[ $allowlocal ]] && conffile="$dracutbasedir/dracut.conf" || \
        conffile="/etc/dracut.conf"
fi

if [[ ! -d $confdir ]]; then
    [[ $allowlocal ]] && confdir="$dracutbasedir/dracut.conf.d" || \
        confdir="/etc/dracut.conf.d"
fi

# source our config file
[[ -f $conffile ]] && . "$conffile"

# source our config dir
if [[ $confdir && -d $confdir ]]; then
    for f in "$confdir"/*.conf; do
        [[ -e $f ]] && . "$f"
    done
fi

# these optins add to the stuff in the config file
if (( ${#add_dracutmodules_l[@]} )); then
    while pop add_dracutmodules_l val; do
        add_dracutmodules+=" $val "
    done
fi

if (( ${#force_add_dracutmodules_l[@]} )); then
    while pop force_add_dracutmodules_l val; do
        force_add_dracutmodules+=" $val "
    done
fi

if (( ${#fscks_l[@]} )); then
    while pop fscks_l val; do
        fscks+=" $val "
    done
fi

if (( ${#add_fstab_l[@]} )); then
    while pop add_fstab_l val; do
        add_fstab+=" $val "
    done
fi

if (( ${#fstab_lines_l[@]} )); then
    while pop fstab_lines_l val; do
        push fstab_lines $val
    done
fi

if (( ${#install_items_l[@]} )); then
    while pop install_items_l val; do
        install_items+=" $val "
    done
fi

# these options override the stuff in the config file
if (( ${#dracutmodules_l[@]} )); then
    dracutmodules=''
    while pop dracutmodules_l val; do
        dracutmodules+="$val "
    done
fi

if (( ${#omit_dracutmodules_l[@]} )); then
    omit_dracutmodules=''
    while pop omit_dracutmodules_l val; do
        omit_dracutmodules+="$val "
    done
fi

if (( ${#filesystems_l[@]} )); then
    filesystems=''
    while pop filesystems_l val; do
        filesystems+="$val "
    done
fi

if (( ${#fw_dir_l[@]} )); then
    fw_dir=''
    while pop fw_dir_l val; do
        fw_dir+="$val "
    done
fi

if (( ${#libdirs_l[@]} )); then
    libdirs=''
    while pop libdirs_l val; do
        libdirs+="$val "
    done
fi

[[ $stdloglvl_l ]] && stdloglvl=$stdloglvl_l
[[ ! $stdloglvl ]] && stdloglvl=4
stdloglvl=$((stdloglvl + verbosity_mod_l))
((stdloglvl > 6)) && stdloglvl=6
((stdloglvl < 0)) && stdloglvl=0

[[ $drivers_dir_l ]] && drivers_dir=$drivers_dir_l
[[ $do_strip_l ]] && do_strip=$do_strip_l
[[ $prefix_l ]] && prefix=$prefix_l
[[ $prefix = "/" ]] && unset prefix
[[ $hostonly_l ]] && hostonly=$hostonly_l
[[ $use_fstab_l ]] && use_fstab=$use_fstab_l
[[ $mdadmconf_l ]] && mdadmconf=$mdadmconf_l
[[ $lvmconf_l ]] && lvmconf=$lvmconf_l
[[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut
[[ $fw_dir ]] || fw_dir="/lib/firmware/updates /lib/firmware"
[[ $tmpdir_l ]] && tmpdir="$tmpdir_l"
[[ $tmpdir ]] || tmpdir=/var/tmp
[[ $do_strip ]] || do_strip=no
[[ $compress_l ]] && compress=$compress_l
[[ $show_modules_l ]] && show_modules=$show_modules_l
[[ $nofscks_l ]] && nofscks="yes"
# eliminate IFS hackery when messing with fw_dir
fw_dir=${fw_dir//:/ }

# handle compression options.
[[ $compress ]] || compress="gzip"
case $compress in
    bzip2) compress="bzip2 -9";;
    lzma)  compress="lzma -9";;
    xz)    compress="xz --check=crc32 --lzma2=dict=1MiB";;
    gzip)  command -v pigz > /dev/null 2>&1 && compress="pigz -9" || \
                                         compress="gzip -9";;
esac
if [[ $_no_compress_l = "cat" ]]; then
    compress="cat"
fi

[[ $hostonly = yes ]] && hostonly="-h"
[[ $hostonly != "-h" ]] && unset hostonly

readonly TMPDIR="$tmpdir"
readonly initdir=$(mktemp --tmpdir="$TMPDIR/" -d -t initramfs.XXXXXX)
[ -d "$initdir" ] || {
    echo "dracut: mktemp --tmpdir=\"$TMPDIR/\" -d -t initramfs.XXXXXXfailed." >&2
    exit 1
}

export DRACUT_KERNEL_LAZY="1"
export DRACUT_RESOLVE_LAZY="1"

if [[ -f $dracutbasedir/dracut-functions.sh ]]; then
    . $dracutbasedir/dracut-functions.sh
else
    echo "dracut: Cannot find $dracutbasedir/dracut-functions.sh." >&2
    echo "dracut: Are you running from a git checkout?" >&2
    echo "dracut: Try passing -l as an argument to $0" >&2
    exit 1
fi

if [[ -f $dracutbasedir/dracut-version.sh ]]; then
    . $dracutbasedir/dracut-version.sh
fi

# Verify bash version, curret minimum is 3.1
if (( ${BASH_VERSINFO[0]} < 3 ||
    ( ${BASH_VERSINFO[0]} == 3 && ${BASH_VERSINFO[1]} < 1 ) )); then
    dfatal 'You need at least Bash 3.1 to use dracut, sorry.'
    exit 1
fi

dracutfunctions=$dracutbasedir/dracut-functions.sh
export dracutfunctions

if (( ${#drivers_l[@]} )); then
    drivers=''
    while pop drivers_l val; do
        drivers+="$val "
    done
fi
drivers=${drivers/-/_}

if (( ${#add_drivers_l[@]} )); then
    while pop add_drivers_l val; do
        add_drivers+=" $val "
    done
fi
add_drivers=${add_drivers/-/_}

if (( ${#omit_drivers_l[@]} )); then
    while pop omit_drivers_l val; do
        omit_drivers+=" $val "
    done
fi
omit_drivers=${omit_drivers/-/_}

omit_drivers_corrected=""
for d in $omit_drivers; do
    strstr " $drivers $add_drivers " " $d " && continue
    omit_drivers_corrected+="$d|"
done
omit_drivers="${omit_drivers_corrected%|}"
unset omit_drivers_corrected


ddebug "Executing $0 $dracut_args"

[[ $do_list = yes ]] && {
    for mod in $dracutbasedir/modules.d/*; do
        [[ -d $mod ]] || continue;
        [[ -e $mod/install || -e $mod/installkernel || \
            -e $mod/module-setup.sh ]] || continue
        echo ${mod##*/??}
    done
    exit 0
}

# This is kinda legacy -- eventually it should go away.
case $dracutmodules in
    ""|auto) dracutmodules="all" ;;
esac

abs_outfile=$(readlink -f "$outfile") && outfile="$abs_outfile"

[[ -f $srcmods/modules.dep ]] || {
    dfatal "$srcmods/modules.dep is missing. Did you run depmod?"
    exit 1
}

if [[ -f $outfile && ! $force ]]; then
    dfatal "Will not override existing initramfs ($outfile) without --force"
    exit 1
fi

outdir=${outfile%/*}
[[ $outdir ]] || outdir="/"

if [[ ! -d "$outdir" ]]; then
    dfatal "Can't write $outfile: Directory $outdir does not exist."
    exit 1
elif [[ ! -w "$outdir" ]]; then
    dfatal "No permission to write $outdir."
    exit 1
elif [[ -f "$outfile" && ! -w "$outfile" ]]; then
    dfatal "No permission to write $outfile."
    exit 1
fi

# clean up after ourselves no matter how we die.
trap 'ret=$?;[[ $keep ]] && echo "Not removing $initdir." >&2 || rm -rf "$initdir";exit $ret;' EXIT
# clean up after ourselves no matter how we die.
trap 'exit 1;' SIGINT

# Need to be able to have non-root users read stuff (rpcbind etc)
chmod 755 "$initdir"

for line in "${fstab_lines[@]}"; do
    set -- $line
    #dev mp fs fsopts
    push host_devs "$1"
    push host_fs_types "$1|$3"
done

for f in $add_fstab; do
    [ -e $f ] || continue
    while read dev rest; do
        push host_devs $dev
    done < $f
done

if [[ $hostonly ]]; then
    # in hostonly mode, determine all devices, which have to be accessed
    # and examine them for filesystem types

    push host_mp \
        "/" \
        "/etc" \
        "/usr" \
        "/usr/bin" \
        "/usr/sbin" \
        "/usr/lib" \
        "/usr/lib64" \
        "/boot"

    for mp in "${host_mp[@]}"; do
        mountpoint "$mp" >/dev/null 2>&1 || continue
        push host_devs $(readlink -f "/dev/block/$(find_block_device "$mp")")
    done
fi

_get_fs_type() (
    [[ $1 ]] || return
    if [[ -b $1 ]] && get_fs_env $1; then
        echo "$(readlink -f $1)|$ID_FS_TYPE"
        return 1
    fi
    if [[ -b /dev/block/$1 ]] && get_fs_env /dev/block/$1; then
        echo "$(readlink -f /dev/block/$1)|$ID_FS_TYPE"
        return 1
    fi
    if fstype=$(find_dev_fstype $1); then
        echo "$1|$fstype"
        return 1
    fi
    return 1
)

for dev in "${host_devs[@]}"; do
    unset fs_type
    for fstype in $(_get_fs_type $dev) \
        $(check_block_and_slaves _get_fs_type $(get_maj_min $dev)); do
        if ! strstr " ${host_fs_types[*]} " " $fstype ";then
            push host_fs_types "$fstype"
        fi
    done
done

[[ -d $udevdir ]] \
    || udevdir=$(pkg-config udev --variable=udevdir 2>/dev/null)
if ! [[ -d "$udevdir" ]]; then
    [[ -d /lib/udev ]] && udevdir=/lib/udev
    [[ -d /usr/lib/udev ]] && udevdir=/usr/lib/udev
fi

[[ -d $systemdutildir ]] \
    || systemdutildir=$(pkg-config systemd --variable=systemdutildir 2>/dev/null)
[[ -d $systemdsystemunitdir ]] \
    || systemdsystemunitdir=$(pkg-config systemd --variable=systemdsystemunitdir 2>/dev/null)

if ! [[ -d "$systemdutildir" ]]; then
    [[ -d /lib/systemd ]] && systemdutildir=/lib/systemd
    [[ -d /usr/lib/systemd ]] && systemdutildir=/usr/lib/systemd
fi
[[ -d "$systemdsystemunitdir" ]] || systemdsystemunitdir=${systemdutildir}/system

export initdir dracutbasedir dracutmodules drivers \
    fw_dir drivers_dir debug no_kernel kernel_only \
    add_drivers omit_drivers mdadmconf lvmconf filesystems \
    use_fstab fstab_lines libdirs fscks nofscks \
    stdloglvl sysloglvl fileloglvl kmsgloglvl logfile \
    debug host_fs_types host_devs sshkey add_fstab \
    DRACUT_VERSION udevdir systemdutildir systemdsystemunitdir

# Create some directory structure first
[[ $prefix ]] && mkdir -m 0755 -p "${initdir}${prefix}"

[[ -h /lib ]] || mkdir -m 0755 -p "${initdir}${prefix}/lib"
[[ $prefix ]] && ln -sfn "${prefix#/}/lib" "$initdir/lib"

if [[ $prefix ]]; then
    for d in bin etc lib sbin tmp usr var $libdirs; do
        strstr "$d" "/" && continue
        ln -sfn "${prefix#/}/${d#/}" "$initdir/$d"
    done
fi

if [[ $kernel_only != yes ]]; then
    for d in usr/bin usr/sbin bin etc lib sbin tmp usr var var/log var/run var/lock $libdirs; do
        [[ -e "${initdir}${prefix}/$d" ]] && continue
        if [ -L "/$d" ]; then
            inst_symlink "/$d" "${prefix}/$d"
        else
            mkdir -m 0755 -p "${initdir}${prefix}/$d"
        fi
    done

    for d in dev proc sys sysroot root run run/lock run/initramfs; do
        if [ -L "/$d" ]; then
            inst_symlink "/$d"
        else
            mkdir -m 0755 -p "$initdir/$d"
        fi
    done

    ln -sfn /run "$initdir/var/run"
    ln -sfn /run/lock "$initdir/var/lock"
else
    for d in lib "$libdir"; do
        [[ -e "${initdir}${prefix}/$d" ]] && continue
        if [ -h "/$d" ]; then
            inst "/$d" "${prefix}/$d"
        else
            mkdir -m 0755 -p "${initdir}${prefix}/$d"
        fi
    done
fi

if [[ $kernel_only != yes ]]; then
    mkdir -p "${initdir}/etc/cmdline.d"
    for _d in $hookdirs; do
        mkdir -m 0755 -p ${initdir}/lib/dracut/hooks/$_d
    done
    if [[ "$UID" = "0" ]]; then
        [ -c ${initdir}/dev/null ] || mknod ${initdir}/dev/null c 1 3
        [ -c ${initdir}/dev/kmsg ] || mknod ${initdir}/dev/kmsg c 1 11
        [ -c ${initdir}/dev/console ] || mknod ${initdir}/dev/console c 5 1
    fi
fi

mods_to_load=""
# check all our modules to see if they should be sourced.
# This builds a list of modules that we will install next.
for_each_module_dir check_module
for_each_module_dir check_mount

strstr "$mods_to_load" "fips" && export DRACUT_FIPS_MODE=1

_isize=0 #initramfs size
modules_loaded=" "
# source our modules.
for moddir in "$dracutbasedir/modules.d"/[0-9][0-9]*; do
    _d_mod=${moddir##*/}; _d_mod=${_d_mod#[0-9][0-9]}
    if strstr "$mods_to_load" " $_d_mod "; then
        [[ $show_modules = yes ]] && echo "$_d_mod" || \
            dinfo "*** Including module: $_d_mod ***"
        if [[ $kernel_only = yes ]]; then
            module_installkernel $_d_mod || {
                dfatal "installkernel failed in module $_d_mod"
                exit 1
            }
        else
            module_install $_d_mod
            if [[ $no_kernel != yes ]]; then
                module_installkernel $_d_mod || {
                    dfatal "installkernel failed in module $_d_mod"
                    exit 1
                }
            fi
        fi
        mods_to_load=${mods_to_load// $_d_mod /}
        modules_loaded+="$_d_mod "

        #print the module install size
        if [ -n "$printsize" ]; then
            _isize_new=$(du -sk ${initdir}|cut -f1)
            _isize_delta=$(($_isize_new - $_isize))
            echo "$_d_mod install size: ${_isize_delta}k"
            _isize=$_isize_new
        fi
    fi
done
unset moddir

for i in $modules_loaded; do
    mkdir -p $initdir/lib/dracut
    echo "$i" >> $initdir/lib/dracut/modules.txt
done

dinfo "*** Including modules done ***"

## final stuff that has to happen
if [[ $no_kernel != yes ]]; then
    dinfo "*** Installing kernel module dependencies and firmware ***"
    dracut_kernel_post
    dinfo "*** Installing kernel module dependencies and firmware done ***"
fi

while pop include_src src && pop include_target tgt; do
    if [[ $src && $tgt ]]; then
        if [[ -f $src ]]; then
            inst $src $tgt
        else
            ddebug "Including directory: $src"
            mkdir -p "${initdir}/${tgt}"
            # check for preexisting symlinks, so we can cope with the
            # symlinks to $prefix
            for i in "$src"/*; do
                [[ -e "$i" || -h "$i" ]] || continue
                s=${initdir}/${tgt}/${i#$src/}
                if [[ -d "$i" ]]; then
                    if ! [[ -e "$s" ]]; then
                        mkdir -m 0755 -p "$s"
                        chmod --reference="$i" "$s"
                    fi
                    cp --reflink=auto --sparse=auto -pfLr -t "$s" "$i"/*
                else
                    cp --reflink=auto --sparse=auto -pfLr -t "$s" "$i"
                fi
            done
        fi
    fi
done

if [[ $kernel_only != yes ]]; then
    (( ${#install_items[@]} > 0 )) && dracut_install  ${install_items[@]}

    while pop fstab_lines line; do
        echo "$line 0 0" >> "${initdir}/etc/fstab"
    done

    for f in $add_fstab; do
        cat $f >> "${initdir}/etc/fstab"
    done

    if [[ $DRACUT_RESOLVE_LAZY ]] && [[ -x /usr/bin/dracut-install ]]; then
        dinfo "*** Resolving executable dependencies ***"
        find "$initdir" -type f \
            '(' -perm -0100 -or -perm -0010 -or -perm -0001 ')' \
            -not -path '*.ko' -print0 \
        | xargs -0 dracut-install ${initdir+-D "$initdir"} -R ${DRACUT_FIPS_MODE+-H}
        dinfo "*** Resolving executable dependencies done***"
    fi

    # make sure that library links are correct and up to date
    for f in /etc/ld.so.conf /etc/ld.so.conf.d/*; do
        [[ -f $f ]] && inst_simple "$f"
    done
    if ! ldconfig -r "$initdir"; then
        if [[ $UID = 0 ]]; then
            derror "ldconfig exited ungracefully"
        else
            derror "ldconfig might need uid=0 (root) for chroot()"
        fi
    fi
fi

if (($maxloglvl >= 5)); then
    ddebug "Listing sizes of included files:"
    du -c "$initdir" | sort -n | ddebug
fi

# strip binaries
if [[ $do_strip = yes ]] ; then
    for p in strip xargs find; do
        if ! type -P $p >/dev/null; then
            derror "Could not find '$p'. You should run $0 with '--nostrip'."
            do_strip=no
        fi
    done
fi

if strstr "$modules_loaded" " fips " && command -v prelink >/dev/null; then
    dinfo "*** pre-unlinking files ***"
    for dir in "$initdir/bin" \
       "$initdir/sbin" \
       "$initdir/usr/bin" \
       "$initdir/usr/sbin"; do
        [[ -L "$dir" ]] && continue
        for i in "$dir"/*; do
            [[ -L $i ]] && continue
            [[ -x $i ]] && prelink -u $i &>/dev/null
        done
    done
    dinfo "*** pre-unlinking files done ***"
fi

if [[ $do_strip = yes ]] ; then
    dinfo "*** Stripping files ***"
    find "$initdir" -type f \
        '(' -perm -0100 -or -perm -0010 -or -perm -0001 \
        -or -path '*/lib/modules/*.ko' ')' -print0 \
        | xargs -0 strip -g 2>/dev/null
    dinfo "*** Stripping files done ***"
fi

type hardlink &>/dev/null && {
    dinfo "*** hardlinking files ***"
    hardlink "$initdir" 2>&1
    dinfo "*** hardlinking files done ***"
}

dinfo "*** Creating image file ***"
if ! ( cd "$initdir"; find . |cpio -R 0:0 -H newc -o --quiet| \
    $compress > "$outfile"; ); then
    dfatal "dracut: creation of $outfile failed"
    exit 1
fi
dinfo "*** Creating image file done ***"

dinfo "Wrote $outfile:"
dinfo "$(ls -l "$outfile")"

exit 0
