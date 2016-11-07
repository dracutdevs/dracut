#!/bin/bash --norc
#
# Generator script for a dracut initramfs
# Tries to retain some degree of compatibility with the command line
# of the various mkinitrd implementations out there
#

# Copyright 2005-2013 Red Hat, Inc.  All rights reserved.
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

# Verify bash version, current minimum is 4
if (( BASH_VERSINFO[0] < 4 )); then
    printf -- 'You need at least Bash 4 to use dracut, sorry.' >&2
    exit 1
fi

dracut_args=( "$@" )
readonly dracut_cmd="$(readlink -f $0)"

set -o pipefail

usage() {
    [[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut
    if [[ -f $dracutbasedir/dracut-version.sh ]]; then
        . $dracutbasedir/dracut-version.sh
    fi

#                                                       80x25 linebreak here ^
    cat << EOF
Usage: $dracut_cmd [OPTION]... [<initramfs> [<kernel-version>]]

Version: $DRACUT_VERSION

Creates initial ramdisk images for preloading modules

  -h, --help  Display all options

If a [LIST] has multiple arguments, then you have to put these in quotes.

For example:

    # dracut --add-drivers "module1 module2"  ...

EOF
}

long_usage() {
    [[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut
    if [[ -f $dracutbasedir/dracut-version.sh ]]; then
        . $dracutbasedir/dracut-version.sh
    fi

#                                                       80x25 linebreak here ^
    cat << EOF
Usage: $dracut_cmd [OPTION]... [<initramfs> [<kernel-version>]]

Version: $DRACUT_VERSION

Creates initial ramdisk images for preloading modules

  --kver [VERSION]      Set kernel version to [VERSION].
  -f, --force           Overwrite existing initramfs file.
  -a, --add [LIST]      Add a space-separated list of dracut modules.
  --rebuild         Append arguments to those of existing image and rebuild
  -m, --modules [LIST]  Specify a space-separated list of dracut modules to
                         call when building the initramfs. Modules are located
                         in /usr/lib/dracut/modules.d.
  -o, --omit [LIST]     Omit a space-separated list of dracut modules.
  --force-add [LIST]    Force to add a space-separated list of dracut modules
                         to the default set of modules, when -H is specified.
  -d, --drivers [LIST]  Specify a space-separated list of kernel modules to
                         exclusively include in the initramfs.
  --add-drivers [LIST]  Specify a space-separated list of kernel
                         modules to add to the initramfs.
  --force-drivers [LIST] Specify a space-separated list of kernel
                         modules to add to the initramfs and make sure they
                         are tried to be loaded via modprobe same as passing
                         rd.driver.pre=DRIVER kernel parameter.
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
  --print-cmdline       Print the kernel command line for the given disk layout
  --early-microcode     Combine early microcode with ramdisk
  --no-early-microcode  Do not combine early microcode with ramdisk
  --kernel-cmdline [PARAMETERS] Specify default kernel command line parameters
  --strip               Strip binaries in the initramfs
  --nostrip             Do not strip binaries in the initramfs
  --prelink             Prelink binaries in the initramfs
  --noprelink           Do not prelink binaries in the initramfs
  --hardlink            Hardlink files in the initramfs
  --nohardlink          Do not hardlink files in the initramfs
  --prefix [DIR]        Prefix initramfs files with [DIR]
  --noprefix            Do not prefix initramfs files
  --mdadmconf           Include local /etc/mdadm.conf
  --nomdadmconf         Do not include local /etc/mdadm.conf
  --lvmconf             Include local /etc/lvm/lvm.conf
  --nolvmconf           Do not include local /etc/lvm/lvm.conf
  --fscks [LIST]        Add a space-separated list of fsck helpers.
  --nofscks             Inhibit installation of any fsck helpers.
  --ro-mnt              Mount / and /usr read-only by default.
  -h, --help            This message
  --debug               Output debug information of the build process
  --profile             Output profile information of the build process
  -L, --stdlog [0-6]    Specify logging level (to standard error)
                         0 - suppress any messages
                         1 - only fatal errors
                         2 - all errors
                         3 - warnings
                         4 - info
                         5 - debug info (here starts lots of output)
                         6 - trace info (and even more)
  -v, --verbose         Increase verbosity level
  -q, --quiet           Decrease verbosity level
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
  -N, --no-hostonly     Disables Host-Only mode
  --hostonly-cmdline    Store kernel command line arguments needed
                        in the initramfs
  --no-hostonly-cmdline Do not store kernel command line arguments needed
                        in the initramfs
  --hostonly-i18n       Install only needed keyboard and font files according
                        to the host configuration (default).
  --no-hostonly-i18n    Install all keyboard and font files available.
  --persistent-policy [POLICY]
                        Use [POLICY] to address disks and partitions.
                        POLICY can be any directory name found in /dev/disk.
                        E.g. "by-uuid", "by-label"
  --fstab               Use /etc/fstab to determine the root device.
  --add-fstab [FILE]    Add file to the initramfs fstab
  --mount "[DEV] [MP] [FSTYPE] [FSOPTS]"
                        Mount device [DEV] on mountpoint [MP] with filesystem
                        [FSTYPE] and options [FSOPTS] in the initramfs
  --mount "[MP]"	Same as above, but [DEV], [FSTYPE] and [FSOPTS] are
			determined by looking at the current mounts.
  --add-device "[DEV]"  Bring up [DEV] in initramfs
  -i, --include [SOURCE] [TARGET]
                        Include the files in the SOURCE directory into the
                         Target directory in the final initramfs.
                        If SOURCE is a file, it will be installed to TARGET
                         in the final initramfs.
  -I, --install [LIST]  Install the space separated list of files into the
                         initramfs.
  --install-optional [LIST]  Install the space separated list of files into the
                         initramfs, if they exist.
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
  --lzo                 Compress the generated initramfs using lzop.
                         Make sure that your kernel has lzo support compiled
                         in, otherwise you will not be able to boot.
  --lz4                 Compress the generated initramfs using lz4.
                         Make sure that your kernel has lz4 support compiled
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
  --logfile [FILE]      Logfile to use (overrides configuration setting)
  --reproducible        Create reproducible images
  --no-reproducible     Do not create reproducible images
  --loginstall [DIR]    Log all files installed from the host to [DIR]
  --uefi                Create an UEFI executable with the kernel cmdline and
                        kernel combined
  --uefi-stub [FILE]    Use the UEFI stub [FILE] to create an UEFI executable
  --kernel-image [FILE] location of the kernel image

If [LIST] has multiple arguments, then you have to put these in quotes.

For example:

    # dracut --add-drivers "module1 module2"  ...

EOF
}

# Fills up host_devs stack variable and makes sure there are no duplicates
push_host_devs() {
    local _dev
    for _dev in "$@"; do
        [[ " ${host_devs[@]} " == *" $_dev "* ]] && return
        host_devs+=( "$_dev" )
    done
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

dropindirs_sort()
{
    local suffix=$1; shift
    local -a files
    local f d

    for d in "$@"; do
        for i in "$d/"*"$suffix"; do
            if [[ -e "$i" ]]; then
                printf "%s\n" "${i##*/}"
            fi
        done
    done | sort -Vu | {
        readarray -t files

        for f in "${files[@]}"; do
            for d in "$@"; do
                if [[ -e "$d/$f" ]]; then
                    printf "%s\n" "$d/$f"
                    continue 2
                fi
            done
        done
    }
}

rearrange_params()
{
    # Workaround -i, --include taking 2 arguments
    set -- "${@/--include/++include}"

    # This prevents any long argument ending with "-i"
    # -i, like --opt-i but I think we can just prevent that
    set -- "${@/%-i/++include}"

    TEMP=$(unset POSIXLY_CORRECT; getopt \
        -o "a:m:o:d:I:k:c:L:fvqlHhMN" \
        --long kver: \
        --long add: \
        --long force-add: \
        --long add-drivers: \
        --long force-drivers: \
        --long omit-drivers: \
        --long modules: \
        --long omit: \
        --long drivers: \
        --long filesystems: \
        --long install: \
        --long install-optional: \
        --long fwdir: \
        --long libdirs: \
        --long fscks: \
        --long add-fstab: \
        --long mount: \
        --long device: \
        --long add-device: \
        --long nofscks: \
        --long ro-mnt \
        --long kmoddir: \
        --long conf: \
        --long confdir: \
        --long tmpdir: \
        --long stdlog: \
        --long compress: \
        --long prefix: \
        --long rebuild: \
        --long force \
        --long kernel-only \
        --long no-kernel \
        --long print-cmdline \
        --long kernel-cmdline: \
        --long strip \
        --long nostrip \
        --long prelink \
        --long noprelink \
        --long hardlink \
        --long nohardlink \
        --long noprefix \
        --long mdadmconf \
        --long nomdadmconf \
        --long lvmconf \
        --long nolvmconf \
        --long debug \
        --long profile \
        --long sshkey: \
        --long logfile: \
        --long verbose \
        --long quiet \
        --long local \
        --long hostonly \
        --long host-only \
        --long no-hostonly \
        --long no-host-only \
        --long hostonly-cmdline \
        --long no-hostonly-cmdline \
        --long persistent-policy: \
        --long fstab \
        --long help \
        --long bzip2 \
        --long lzma \
        --long xz \
        --long lzo \
        --long lz4 \
        --long no-compress \
        --long gzip \
        --long list-modules \
        --long show-modules \
        --long keep \
        --long printsize \
        --long regenerate-all \
        --long noimageifnotneeded \
        --long early-microcode \
        --long no-early-microcode \
        --long reproducible \
        --long no-reproducible \
        --long loginstall: \
        --long uefi \
        --long uefi-stub: \
        --long kernel-image: \
        --long no-hostonly-i18n \
        --long hostonly-i18n \
        -- "$@")

    if (( $? != 0 )); then
        usage
        exit 1
    fi
}

verbosity_mod_l=0
unset kernel
unset outfile

rearrange_params "$@"
eval set -- "$TEMP"

# parse command line args to check if '--rebuild' option is present
unset append_args_l
unset rebuild_file
while :
do
	if [ "$1" == "--" ]; then
	    shift; break
	fi
	if [ "$1" == "--rebuild" ]; then
	    append_args_l="yes"
            rebuild_file=$2
            if [ ! -e $rebuild_file ]; then
                echo "Image file '$rebuild_file', for rebuild, does not exist!"
                exit 1
            fi
            abs_rebuild_file=$(readlink -f "$rebuild_file") && rebuild_file="$abs_rebuild_file"
	    shift; continue
	fi
	shift
done

# get output file name and kernel version from command line arguments
while (($# > 0)); do
    case ${1%%=*} in
        ++include)
            shift 2;;
        *)
            if ! [[ ${outfile+x} ]]; then
                outfile=$1
            elif ! [[ ${kernel+x} ]]; then
                kernel=$1
            else
                printf "\nUnknown arguments: %s\n\n" "$*" >&2
                usage; exit 1;
            fi
            ;;
    esac
    shift
done

# extract input image file provided with rebuild option to get previous parameters, if any
if [[ $append_args_l == "yes" ]]; then
    unset rebuild_param

    # determine resultant file
    if ! [[ $outfile ]]; then
        outfile=$rebuild_file
    fi

    if ! rebuild_param=$(lsinitrd $rebuild_file '*lib/dracut/build-parameter.txt'); then
        echo "Image '$rebuild_file' has no rebuild information stored"
        exit 1
    fi

    # prepend previous parameters to current command line args
    if [[ $rebuild_param ]]; then
        TEMP="$rebuild_param $TEMP"
        eval set -- "$TEMP"
        rearrange_params "$@"
    fi

    # clean the temporarily used scratch-pad directory
    rm -rf $scratch_dir
fi

unset PARMS_TO_STORE
PARMS_TO_STORE=""

eval set -- "$TEMP"

while :; do
    if [ $1 != "--" ] && [ $1 != "--rebuild" ]; then
        PARMS_TO_STORE+=" $1";
    fi
    case $1 in
        --kver)        kernel="$2";                           PARMS_TO_STORE+=" '$2'"; shift;;
        -a|--add)      add_dracutmodules_l+=("$2");           PARMS_TO_STORE+=" '$2'"; shift;;
        --force-add)   force_add_dracutmodules_l+=("$2");     PARMS_TO_STORE+=" '$2'"; shift;;
        --add-drivers) add_drivers_l+=("$2");                 PARMS_TO_STORE+=" '$2'"; shift;;
        --force-drivers) force_drivers_l+=("$2");             PARMS_TO_STORE+=" '$2'"; shift;;
        --omit-drivers) omit_drivers_l+=("$2");               PARMS_TO_STORE+=" '$2'"; shift;;
        -m|--modules)  dracutmodules_l+=("$2");               PARMS_TO_STORE+=" '$2'"; shift;;
        -o|--omit)     omit_dracutmodules_l+=("$2");          PARMS_TO_STORE+=" '$2'"; shift;;
        -d|--drivers)  drivers_l+=("$2");                     PARMS_TO_STORE+=" '$2'"; shift;;
        --filesystems) filesystems_l+=("$2");                 PARMS_TO_STORE+=" '$2'"; shift;;
        -I|--install)  install_items_l+=("$2");               PARMS_TO_STORE+=" '$2'"; shift;;
        --install-optional) install_optional_items_l+=("$2"); PARMS_TO_STORE+=" '$2'"; shift;;
        --fwdir)       fw_dir_l+=("$2");                      PARMS_TO_STORE+=" '$2'"; shift;;
        --libdirs)     libdirs_l+=("$2");                     PARMS_TO_STORE+=" '$2'"; shift;;
        --fscks)       fscks_l+=("$2");                       PARMS_TO_STORE+=" '$2'"; shift;;
        --add-fstab)   add_fstab_l+=("$2");                   PARMS_TO_STORE+=" '$2'"; shift;;
        --mount)       fstab_lines+=("$2");                   PARMS_TO_STORE+=" '$2'"; shift;;
        --add-device|--device) add_device_l+=("$2");          PARMS_TO_STORE+=" '$2'"; shift;;
        --kernel-cmdline) kernel_cmdline_l+=("$2");           PARMS_TO_STORE+=" '$2'"; shift;;
        --nofscks)     nofscks_l="yes";;
        --ro-mnt)      ro_mnt_l="yes";;
        -k|--kmoddir)  drivers_dir_l="$2";             PARMS_TO_STORE+=" '$2'"; shift;;
        -c|--conf)     conffile="$2";                  PARMS_TO_STORE+=" '$2'"; shift;;
        --confdir)     confdir="$2";                   PARMS_TO_STORE+=" '$2'"; shift;;
        --tmpdir)      tmpdir_l="$2";                  PARMS_TO_STORE+=" '$2'"; shift;;
        -L|--stdlog)   stdloglvl_l="$2";               PARMS_TO_STORE+=" '$2'"; shift;;
        --compress)    compress_l="$2";                PARMS_TO_STORE+=" '$2'"; shift;;
        --prefix)      prefix_l="$2";                  PARMS_TO_STORE+=" '$2'"; shift;;
        --loginstall)  loginstall_l="$2";              PARMS_TO_STORE+=" '$2'"; shift;;
        --rebuild)     if [ $rebuild_file == $outfile ]; then
                           force=yes
                       fi
                       shift
                       ;;
        -f|--force)    force=yes;;
        --kernel-only) kernel_only="yes"; no_kernel="no";;
        --no-kernel)   kernel_only="no"; no_kernel="yes";;
        --print-cmdline)
                       print_cmdline="yes"; hostonly_l="yes"; kernel_only="yes"; no_kernel="yes";;
        --early-microcode)
                       early_microcode_l="yes";;
        --no-early-microcode)
                       early_microcode_l="no";;
        --strip)       do_strip_l="yes";;
        --nostrip)     do_strip_l="no";;
        --prelink)     do_prelink_l="yes";;
        --noprelink)   do_prelink_l="no";;
        --hardlink)    do_hardlink_l="yes";;
        --nohardlink)  do_hardlink_l="no";;
        --noprefix)    prefix_l="/";;
        --mdadmconf)   mdadmconf_l="yes";;
        --nomdadmconf) mdadmconf_l="no";;
        --lvmconf)     lvmconf_l="yes";;
        --nolvmconf)   lvmconf_l="no";;
        --debug)       debug="yes";;
        --profile)     profile="yes";;
        --sshkey)      sshkey="$2";                    PARMS_TO_STORE+=" '$2'"; shift;;
        --logfile)     logfile_l="$2"; shift;;
        -v|--verbose)  ((verbosity_mod_l++));;
        -q|--quiet)    ((verbosity_mod_l--));;
        -l|--local)
                       allowlocal="yes"
                       [[ -f "$(readlink -f "${0%/*}")/dracut-init.sh" ]] \
                           && dracutbasedir="$(readlink -f "${0%/*}")"
                       ;;
        -H|--hostonly|--host-only)
                       hostonly_l="yes" ;;
        -N|--no-hostonly|--no-host-only)
                       hostonly_l="no" ;;
        --hostonly-cmdline)
                       hostonly_cmdline_l="yes" ;;
        --hostonly-i18n)
                       i18n_install_all_l="no" ;;
        --no-hostonly-i18n)
                       i18n_install_all_l="yes" ;;
        --no-hostonly-cmdline)
                       hostonly_cmdline_l="no" ;;
        --persistent-policy)
                       persistent_policy_l="$2";       PARMS_TO_STORE+=" '$2'"; shift;;
        --fstab)       use_fstab_l="yes" ;;
        -h|--help)     long_usage; exit 1 ;;
        -i|--include)  include_src+=("$2");          PARMS_TO_STORE+=" '$2'";
                       shift;;
        --bzip2)       compress_l="bzip2";;
        --lzma)        compress_l="lzma";;
        --xz)          compress_l="xz";;
        --lzo)         compress_l="lzo";;
        --lz4)         compress_l="lz4";;
        --no-compress) _no_compress_l="cat";;
        --gzip)        compress_l="gzip";;
        --list-modules) do_list="yes";;
        -M|--show-modules)
                       show_modules_l="yes"
                       ;;
        --keep)        keep="yes";;
        --printsize)   printsize="yes";;
        --regenerate-all) regenerate_all="yes";;
        --noimageifnotneeded) noimageifnotneeded="yes";;
        --reproducible) reproducible_l="yes";;
        --no-reproducible) reproducible_l="no";;
        --uefi)        uefi="yes";;
        --uefi-stub)
                       uefi_stub_l="$2";               PARMS_TO_STORE+=" '$2'"; shift;;
        --kernel-image)
                       kernel_image_l="$2";            PARMS_TO_STORE+=" '$2'"; shift;;
        --) shift; break;;

        *)  # should not even reach this point
            printf "\n!Unknown option: '%s'\n\n" "$1" >&2; usage; exit 1;;
    esac
    shift
done

# getopt cannot handle multiple arguments, so just handle "-I,--include"
# the old fashioned way

while (($# > 0)); do
    if [ "${1%%=*}" == "++include" ]; then
        include_src+=("$2")
        include_target+=("$3")
        PARMS_TO_STORE+=" --include '$2' '$3'"
        shift 2
    fi
    shift
done

if [[ $regenerate_all == "yes" ]]; then
    ret=0
    if [[ $kernel ]]; then
        printf -- "--regenerate-all cannot be called with a kernel version\n" >&2
        exit 1
    fi

    if [[ $outfile ]]; then
        printf -- "--regenerate-all cannot be called with a image file\n" >&2
        exit 1
    fi

    ((len=${#dracut_args[@]}))
    for ((i=0; i < len; i++)); do
        [[ ${dracut_args[$i]} == "--regenerate-all" ]] && \
            unset dracut_args[$i]
    done

    cd /lib/modules
    for i in *; do
        [[ -f $i/modules.dep ]] || [[ -f $i/modules.dep.bin ]] || continue
        "$dracut_cmd" --kver="$i" "${dracut_args[@]}"
        ((ret+=$?))
    done
    exit $ret
fi

if ! [[ $kernel ]]; then
    kernel=$(uname -r)
fi

if [[ $kernel ]]; then
    if ! [[ -d /lib/modules/$kernel ]] && [[ $no_kernel != yes ]]; then
        printf -- "Kernel version $kernel has no module directory /lib/modules/$kernel\n" >&2
    fi
fi

if ! [[ $outfile ]]; then
    [[ -f /etc/machine-id ]] && read MACHINE_ID < /etc/machine-id

    if [[ $MACHINE_ID ]] && ( [[ -d /boot/${MACHINE_ID} ]] || [[ -L /boot/${MACHINE_ID} ]] ); then
        outfile="/boot/${MACHINE_ID}/$kernel/initrd"
    else
        outfile="/boot/initramfs-$kernel.img"
    fi
fi

unset LC_MESSAGES
unset LC_CTYPE
export LC_ALL=C
export LANG=C
unset LD_LIBRARY_PATH
unset LD_PRELOAD
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
    if [[ $allowlocal ]]; then
        conffile="$dracutbasedir/dracut.conf"
    else
        conffile="/etc/dracut.conf"
    fi
fi

if [[ ! -d $confdir ]]; then
    if [[ $allowlocal ]]; then
        confdir="$dracutbasedir/dracut.conf.d"
    else
        confdir="/etc/dracut.conf.d"
    fi
fi

# source our config file
[[ -f $conffile ]] && . "$conffile"

# source our config dir
for f in $(dropindirs_sort ".conf" "$confdir" "$dracutbasedir/dracut.conf.d"); do
    [[ -e $f ]] && . "$f"
done

DRACUT_PATH=${DRACUT_PATH:-/sbin /bin /usr/sbin /usr/bin}

for i in $DRACUT_PATH; do
    rl=$i
    if [ -L "$i" ]; then
        rl=$(readlink -f $i)
    fi
    if [[ "$NPATH" != *:$rl* ]] ; then
        NPATH+=":$rl"
    fi
done
export PATH="${NPATH#:}"
unset NPATH

# these options add to the stuff in the config file
(( ${#add_dracutmodules_l[@]} )) && add_dracutmodules+=" ${add_dracutmodules_l[@]} "
(( ${#force_add_dracutmodules_l[@]} )) && force_add_dracutmodules+=" ${force_add_dracutmodules_l[@]} "
(( ${#fscks_l[@]} )) && fscks+=" ${fscks_l[@]} "
(( ${#add_fstab_l[@]} )) && add_fstab+=" ${add_fstab_l[@]} "
(( ${#fstab_lines_l[@]} )) && fstab_lines+=( "${fstab_lines_l[@]}" )
(( ${#install_items_l[@]} )) && install_items+=" ${install_items_l[@]} "
(( ${#install_optional_items_l[@]} )) && install_optional_items+=" ${install_optional_items_l[@]} "

# these options override the stuff in the config file
(( ${#dracutmodules_l[@]} )) && dracutmodules="${dracutmodules_l[@]}"
(( ${#omit_dracutmodules_l[@]} )) && omit_dracutmodules="${omit_dracutmodules_l[@]}"
(( ${#filesystems_l[@]} )) && filesystems="${filesystems_l[@]}"
(( ${#fw_dir_l[@]} )) && fw_dir="${fw_dir_l[@]}"
(( ${#libdirs_l[@]} ))&& libdirs="${libdirs_l[@]}"

[[ $stdloglvl_l ]] && stdloglvl=$stdloglvl_l
[[ ! $stdloglvl ]] && stdloglvl=4
stdloglvl=$((stdloglvl + verbosity_mod_l))
((stdloglvl > 6)) && stdloglvl=6
((stdloglvl < 0)) && stdloglvl=0

[[ $drivers_dir_l ]] && drivers_dir=$drivers_dir_l
[[ $do_strip_l ]] && do_strip=$do_strip_l
[[ $do_strip ]] || do_strip=yes
[[ $do_prelink_l ]] && do_prelink=$do_prelink_l
[[ $do_prelink ]] || do_prelink=yes
[[ $do_hardlink_l ]] && do_hardlink=$do_hardlink_l
[[ $do_hardlink ]] || do_hardlink=yes
[[ $prefix_l ]] && prefix=$prefix_l
[[ $prefix = "/" ]] && unset prefix
[[ $hostonly_l ]] && hostonly=$hostonly_l
[[ $hostonly_cmdline_l ]] && hostonly_cmdline=$hostonly_cmdline_l
[[ "$hostonly" == "yes" ]] && ! [[ $hostonly_cmdline ]] && hostonly_cmdline="yes"
[[ $i18n_install_all_l ]] && i18n_install_all=$i18n_install_all_l
[[ $persistent_policy_l ]] && persistent_policy=$persistent_policy_l
[[ $use_fstab_l ]] && use_fstab=$use_fstab_l
[[ $mdadmconf_l ]] && mdadmconf=$mdadmconf_l
[[ $lvmconf_l ]] && lvmconf=$lvmconf_l
[[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut
[[ $fw_dir ]] || fw_dir="/lib/firmware/updates:/lib/firmware:/lib/firmware/$kernel"
[[ $tmpdir_l ]] && tmpdir="$tmpdir_l"
[[ $tmpdir ]] || tmpdir=/var/tmp
[[ $INITRD_COMPRESS ]] && compress=$INITRD_COMPRESS
[[ $compress_l ]] && compress=$compress_l
[[ $show_modules_l ]] && show_modules=$show_modules_l
[[ $nofscks_l ]] && nofscks="yes"
[[ $ro_mnt_l ]] && ro_mnt="yes"
[[ $early_microcode_l ]] && early_microcode=$early_microcode_l
[[ $early_microcode ]] || early_microcode=no
[[ $logfile_l ]] && logfile="$logfile_l"
[[ $reproducible_l ]] && reproducible="$reproducible_l"
[[ $loginstall_l ]] && loginstall="$loginstall_l"
[[ $uefi_stub_l ]] && uefi_stub="$uefi_stub_l"
[[ $kernel_image_l ]] && kernel_image="$kernel_image_l"

# eliminate IFS hackery when messing with fw_dir
export DRACUT_FIRMWARE_PATH=${fw_dir// /:}
fw_dir=${fw_dir//:/ }

# check for logfile and try to create one if it doesn't exist
if [[ -n "$logfile" ]];then
    if [[ ! -f "$logfile" ]];then
        touch "$logfile"
        if [ ! $? -eq 0 ] ;then
            printf "%s\n" "dracut: touch $logfile failed." >&2
        fi
    fi
fi

# handle compression options.
if [[ $_no_compress_l = "cat" ]]; then
    compress="cat"
fi

if ! [[ $compress ]]; then
    # check all known compressors, if none specified
    for i in pigz gzip lz4 lzop lzma xz lbzip2 bzip2 cat; do
        command -v "$i" &>/dev/null || continue
        compress="$i"
        break
    done
    if [[ $compress = cat ]]; then
            printf "%s\n" "dracut: no compression tool available. Initramfs image is going to be big." >&2
    fi
fi

# choose the right arguments for the compressor
case $compress in
    bzip2|lbzip2)
        if [[ "$compress" =  lbzip2 ]] || command -v lbzip2 &>/dev/null; then
            compress="lbzip2 -9"
        else
            compress="bzip2 -9"
        fi
        ;;
    lzma)
        compress="lzma -9 -T0"
        ;;
    xz)
        compress="xz --check=crc32 --lzma2=dict=1MiB -T0"
        ;;
    gzip|pigz)
        if [[ "$compress" = pigz ]] || command -v pigz &>/dev/null; then
            compress="pigz -9 -n -T -R"
        elif command -v gzip &>/dev/null && gzip --help 2>&1 | grep -q rsyncable; then
            compress="gzip -n -9 --rsyncable"
        else
            compress="gzip -n -9"
        fi
        ;;
    lzo|lzop)
        compress="lzop -9"
        ;;
    lz4)
        compress="lz4 -l -9"
        ;;
esac

[[ $hostonly = yes ]] && hostonly="-h"
[[ $hostonly != "-h" ]] && unset hostonly

[[ $reproducible == yes ]] && DRACUT_REPRODUCIBLE=1

readonly TMPDIR="$tmpdir"
readonly DRACUT_TMPDIR="$(mktemp -p "$TMPDIR/" -d -t dracut.XXXXXX)"
[ -d "$DRACUT_TMPDIR" ] || {
    printf "%s\n" "dracut: mktemp -p '$TMPDIR/' -d -t dracut.XXXXXX failed." >&2
    exit 1
}

# clean up after ourselves no matter how we die.
trap '
    ret=$?;
    [[ $keep ]] && echo "Not removing $DRACUT_TMPDIR." >&2 || { [[ $DRACUT_TMPDIR ]] && rm -rf -- "$DRACUT_TMPDIR"; };
    exit $ret;
    ' EXIT

# clean up after ourselves no matter how we die.
trap 'exit 1;' SIGINT

readonly initdir="${DRACUT_TMPDIR}/initramfs"
mkdir "$initdir"

if [[ $early_microcode = yes ]] || ( [[ $acpi_override = yes ]] && [[ -d $acpi_table_dir ]] ); then
    readonly early_cpio_dir="${DRACUT_TMPDIR}/earlycpio"
    mkdir "$early_cpio_dir"
fi

export DRACUT_RESOLVE_LAZY="1"

if [[ $print_cmdline ]]; then
    stdloglvl=0
    sysloglvl=0
    fileloglvl=0
    kmsgloglvl=0
fi

if [[ -f $dracutbasedir/dracut-version.sh ]]; then
    . $dracutbasedir/dracut-version.sh
fi

if [[ -f $dracutbasedir/dracut-init.sh ]]; then
    . $dracutbasedir/dracut-init.sh
else
    printf "%s\n" "dracut: Cannot find $dracutbasedir/dracut-init.sh." >&2
    printf "%s\n" "dracut: Are you running from a git checkout?" >&2
    printf "%s\n" "dracut: Try passing -l as an argument to $dracut_cmd" >&2
    exit 1
fi

if ! [[ $print_cmdline ]]; then
    inst /bin/sh
    if ! $DRACUT_INSTALL ${initdir:+-D "$initdir"} -R "$initdir/bin/sh" &>/dev/null; then
        unset DRACUT_RESOLVE_LAZY
        export DRACUT_RESOLVE_DEPS=1
    fi
    rm -fr -- ${initdir}/*
fi

dracutfunctions=$dracutbasedir/dracut-functions.sh
export dracutfunctions

(( ${#drivers_l[@]} )) && drivers="${drivers_l[@]}"
drivers=${drivers/-/_}

(( ${#add_drivers_l[@]} )) && add_drivers+=" ${add_drivers_l[@]} "
add_drivers=${add_drivers/-/_}

(( ${#force_drivers_l[@]} )) && force_drivers+=" ${force_drivers_l[@]} "
force_drivers=${force_drivers/-/_}

(( ${#omit_drivers_l[@]} )) && omit_drivers+=" ${omit_drivers_l[@]} "
omit_drivers=${omit_drivers/-/_}

(( ${#kernel_cmdline_l[@]} )) && kernel_cmdline+=" ${kernel_cmdline_l[@]} "

omit_drivers_corrected=""
for d in $omit_drivers; do
    [[ " $drivers $add_drivers " == *\ $d\ * ]] && continue
    [[ " $drivers $force_drivers " == *\ $d\ * ]] && continue
    omit_drivers_corrected+="$d|"
done
omit_drivers="${omit_drivers_corrected%|}"
unset omit_drivers_corrected

# prepare args for logging
for ((i=0; i < ${#dracut_args[@]}; i++)); do
    [[ "${dracut_args[$i]}" == *\ * ]] && \
        dracut_args[$i]="\"${dracut_args[$i]}\""
        #" keep vim happy
done

dinfo "Executing: $dracut_cmd ${dracut_args[@]}"

[[ $do_list = yes ]] && {
    for mod in $dracutbasedir/modules.d/*; do
        [[ -d $mod ]] || continue;
        [[ -e $mod/install || -e $mod/installkernel || \
            -e $mod/module-setup.sh ]] || continue
        printf "%s\n" "${mod##*/??}"
    done
    exit 0
}

# This is kinda legacy -- eventually it should go away.
case $dracutmodules in
    ""|auto) dracutmodules="all" ;;
esac

abs_outfile=$(readlink -f "$outfile") && outfile="$abs_outfile"

if [[ $no_kernel != yes ]] && [[ -d $srcmods ]]; then
    if ! [[ -f $srcmods/modules.dep ]]; then
        if [[ -n "$(find "$srcmods" -name '*.ko*')" ]]; then
            dfatal "$srcmods/modules.dep is missing. Did you run depmod?"
            exit 1
        else
            dwarn "$srcmods/modules.dep is missing. Did you run depmod?"
        fi
    elif ! ( command -v gzip &>/dev/null && command -v xz &>/dev/null); then
        read _mod < $srcmods/modules.dep
        _mod=${_mod%%:*}
        if [[ -f $srcmods/"$_mod" ]]; then
            # Check, if kernel modules are compressed, and if we can uncompress them
            case "$_mod" in
                *.ko.gz) kcompress=gzip;;
                *.ko.xz) kcompress=xz;;
            esac
            if [[ $kcompress ]]; then
                if ! command -v "$kcompress" &>/dev/null; then
                    dfatal "Kernel modules are compressed with $kcompress, but $kcompress is not available."
                    exit 1
                fi
            fi
        fi
    fi
fi

if [[ ! $print_cmdline ]]; then
    if [[ -f $outfile && ! $force ]]; then
        dfatal "Will not override existing initramfs ($outfile) without --force"
        exit 1
    fi

    outdir=${outfile%/*}
    [[ $outdir ]] || outdir="/"

    if [[ ! -d "$outdir" ]]; then
        dfatal "Can't write to $outdir: Directory $outdir does not exist or is not accessible."
        exit 1
    elif [[ ! -w "$outdir" ]]; then
        dfatal "No permission to write to $outdir."
        exit 1
    elif [[ -f "$outfile" && ! -w "$outfile" ]]; then
        dfatal "No permission to write $outfile."
        exit 1
    fi

    if [[ $loginstall ]]; then
        if ! mkdir -p "$loginstall"; then
            dfatal "Could not create directory to log installed files to '$loginstall'."
            exit 1
        fi
        loginstall=$(readlink -f "$loginstall")
    fi

    if [[ $uefi = yes ]]; then
        if ! command -v objcopy &>/dev/null; then
            dfatal "Need 'objcopy' to create a UEFI executable"
            exit 1
        fi
        unset EFI_MACHINE_TYPE_NAME
        case $(arch) in
            x86_64)
                EFI_MACHINE_TYPE_NAME=x64;;
            ia32)
                EFI_MACHINE_TYPE_NAME=ia32;;
            *)
                dfatal "Architecture '$(arch)' not supported to create a UEFI executable"
                exit 1
                ;;
        esac

        if ! [[ -s $uefi_stub ]]; then
            for uefi_stub in \
                "/lib/systemd/boot/efi/linux${EFI_MACHINE_TYPE_NAME}.efi.stub" \
                    "/usr/lib/gummiboot/linux${EFI_MACHINE_TYPE_NAME}.efi.stub"; do
                [[ -s $uefi_stub ]] || continue
                break
            done
        fi
        if ! [[ -s $uefi_stub ]]; then
            dfatal "Can't find a uefi stub '$uefi_stub' to create a UEFI executable"
            exit 1
        fi

        if ! [[ $kernel_image ]]; then
            for kernel_image in "/lib/modules/$kernel/vmlinuz" "/boot/vmlinuz-$kernel"; do
                [[ -s "$kernel_image" ]] || continue
                break
            done
        fi
        if ! [[ -s $kernel_image ]]; then
            dfatal "Can't find a kernel image '$kernel_image' to create a UEFI executable"
            exit 1
        fi
    fi
fi

if [[ $acpi_override = yes ]] && ! check_kernel_config CONFIG_ACPI_INITRD_TABLE_OVERRIDE; then
    dwarn "Disabling ACPI override, because kernel does not support it. CONFIG_ACPI_INITRD_TABLE_OVERRIDE!=y"
    unset acpi_override
fi

if [[ $early_microcode = yes ]]; then
    if [[ $hostonly ]]; then
        [[ $(get_cpu_vendor) == "AMD" ]] \
            && ! check_kernel_config CONFIG_MICROCODE_AMD \
            && unset early_microcode
        [[ $(get_cpu_vendor) == "Intel" ]] \
            && ! check_kernel_config CONFIG_MICROCODE_INTEL \
            && unset early_microcode
    else
        ! check_kernel_config CONFIG_MICROCODE_AMD \
            && ! check_kernel_config CONFIG_MICROCODE_INTEL \
            && unset early_microcode
    fi
    [[ $early_microcode != yes ]] \
        && dwarn "Disabling early microcode, because kernel does not support it. CONFIG_MICROCODE_[AMD|INTEL]!=y"
fi

# Need to be able to have non-root users read stuff (rpcbind etc)
chmod 755 "$initdir"

if [[ $hostonly ]]; then
    for i in /sys /proc /run /dev; do
        if ! findmnt --target "$i" &>/dev/null; then
            dwarning "Turning off host-only mode: '$i' is not mounted!"
            unset hostonly
        fi
    done
fi

declare -A host_fs_types

for line in "${fstab_lines[@]}"; do
    set -- $line
    dev="$1"
    #dev mp fs fsopts
    case "$dev" in
        UUID=*)
            dev=$(blkid -l -t UUID=${dev#UUID=} -o device)
            ;;
        LABEL=*)
            dev=$(blkid -l -t LABEL=${dev#LABEL=} -o device)
            ;;
        PARTUUID=*)
            dev=$(blkid -l -t PARTUUID=${dev#PARTUUID=} -o device)
            ;;
        PARTLABEL=*)
            dev=$(blkid -l -t PARTLABEL=${dev#PARTLABEL=} -o device)
            ;;
    esac
    [ -z "$dev" ] && dwarn "Bad fstab entry $@" && continue
    if [[ "$3" == btrfs ]]; then
        for i in $(btrfs_devs "$2"); do
            push_host_devs "$i"
        done
    fi
    push_host_devs "$dev"
    host_fs_types["$dev"]="$3"
done

for f in $add_fstab; do
    [[ -e $f ]] || continue
    while read dev rest || [ -n "$dev" ]; do
        push_host_devs "$dev"
    done < "$f"
done

for dev in $add_device; do
    push_host_devs "$dev"
done

if (( ${#add_device_l[@]} )); then
    add_device+=" ${add_device_l[@]} "
    push_host_devs "${add_device_l[@]}"
fi

if [[ $hostonly ]]; then
    # in hostonly mode, determine all devices, which have to be accessed
    # and examine them for filesystem types

    for mp in \
        "/" \
        "/etc" \
        "/bin" \
        "/sbin" \
        "/lib" \
        "/lib64" \
        "/usr" \
        "/usr/bin" \
        "/usr/sbin" \
        "/usr/lib" \
        "/usr/lib64" \
        "/boot" \
        "/boot/efi" \
        ;
    do
        mp=$(readlink -f "$mp")
        mountpoint "$mp" >/dev/null 2>&1 || continue
        _dev=$(find_block_device "$mp")
        _bdev=$(readlink -f "/dev/block/$_dev")
        [[ -b $_bdev ]] && _dev=$_bdev
        [[ "$mp" == "/" ]] && root_devs+=("$_dev")
        push_host_devs "$_dev"
        if [[ $(find_mp_fstype "$mp") == btrfs ]]; then
            for i in $(btrfs_devs "$mp"); do
                [[ "$mp" == "/" ]] && root_devs+=("$i")
                push_host_devs "$i"
            done
        fi
    done

    if [[ -f /proc/swaps ]] && [[ -f /etc/fstab ]]; then
        while read dev type rest || [ -n "$dev" ]; do
            [[ -b $dev ]] || continue
            [[ "$type" == "partition" ]] || continue

            while read _d _m _t _o _r || [ -n "$_d" ]; do
                [[ "$_d" == \#* ]] && continue
                [[ $_d ]] || continue
                [[ $_t != "swap" ]] && continue
                [[ $_m != "swap" ]] && [[ $_m != "none" ]] && continue
                [[ "$_o" == *noauto* ]] && continue
                _d=$(expand_persistent_dev "$_d")
                [[ "$_d" -ef "$dev" ]] || continue

                if [[ -f /etc/crypttab ]]; then
                    while read _mapper _a _p _o || [ -n "$_mapper" ]; do
                        [[ $_mapper = \#* ]] && continue
                        [[ "$_d" -ef /dev/mapper/"$_mapper" ]] || continue
                        [[ "$_o" ]] || _o="$_p"
                        # skip entries with password files
                        [[ "$_p" == /* ]] && [[ -f $_p ]] && continue 2
                        # skip mkswap swap
                        [[ $_o == *swap* ]] && continue 2
                    done < /etc/crypttab
                fi

                _dev="$(readlink -f "$dev")"
                push_host_devs "$_dev"
                swap_devs+=("$_dev")
                break
            done < /etc/fstab
        done < /proc/swaps
    fi

    # collect all "x-initrd.mount" entries from /etc/fstab
    if [[ -f /etc/fstab ]]; then
        while read _d _m _t _o _r || [ -n "$_d" ]; do
            [[ "$_d" == \#* ]] && continue
            [[ $_d ]] || continue
            [[ "$_o" != *x-initrd.mount* ]] && continue
            _dev=$(expand_persistent_dev "$_d")
            _dev="$(readlink -f "$_dev")"
            [[ -b $_dev ]] || continue

            push_host_devs "$_dev"
            if [[ "$_t" == btrfs ]]; then
                for i in $(find_btrfs_devs "$_m"); do
                    push_host_devs "$i"
                done
            fi
        done < /etc/fstab
    fi
fi

unset m
unset rest

_get_fs_type() {
    [[ $1 ]] || return
    if [[ -b /dev/block/$1 ]]; then
        ID_FS_TYPE=$(get_fs_env "/dev/block/$1") && host_fs_types["$(readlink -f "/dev/block/$1")"]="$ID_FS_TYPE"
        return 1
    fi
    if [[ -b $1 ]]; then
        ID_FS_TYPE=$(get_fs_env "$1") && host_fs_types["$(readlink -f "$1")"]="$ID_FS_TYPE"
        return 1
    fi
    if fstype=$(find_dev_fstype "$1"); then
        host_fs_types["$1"]="$fstype"
        return 1
    fi
    return 1
}

for dev in "${host_devs[@]}"; do
    _get_fs_type "$dev"
    check_block_and_slaves_all _get_fs_type "$(get_maj_min "$dev")"
done

for dev in "${!host_fs_types[@]}"; do
    [[ ${host_fs_types[$dev]} = "reiserfs" ]] || [[ ${host_fs_types[$dev]} = "xfs" ]] || continue
    rootopts=$(find_dev_fsopts "$dev")
    if [[ ${host_fs_types[$dev]} = "reiserfs" ]]; then
        journaldev=$(fs_get_option $rootopts "jdev")
    elif [[ ${host_fs_types[$dev]} = "xfs" ]]; then
        journaldev=$(fs_get_option $rootopts "logdev")
    fi
    if [[ $journaldev ]]; then
        dev="$(readlink -f "$dev")"
        push_host_devs "$dev"
        _get_fs_type "$dev"
        check_block_and_slaves_all _get_fs_type "$(get_maj_min "$dev")"
    fi
done

[[ -d $udevdir ]] \
    || udevdir="$(pkg-config udev --variable=udevdir 2>/dev/null)"
if ! [[ -d "$udevdir" ]]; then
    [[ ! -h /lib ]] && [[ -d /lib/udev ]] && udevdir=/lib/udev
    [[ -d /usr/lib/udev ]] && udevdir=/usr/lib/udev
fi

[[ -d $systemdutildir ]] \
    || systemdutildir=$(pkg-config systemd --variable=systemdutildir 2>/dev/null)

if ! [[ -d "$systemdutildir" ]]; then
    [[ ! -h /lib ]] && [[ -d /lib/systemd ]] && systemdutildir=/lib/systemd
    [[ -d /usr/lib/systemd ]] && systemdutildir=/usr/lib/systemd
fi

[[ -d $systemdsystemunitdir ]] \
    || systemdsystemunitdir=$(pkg-config systemd --variable=systemdsystemunitdir 2>/dev/null)

[[ -d "$systemdsystemunitdir" ]] || systemdsystemunitdir=${systemdutildir}/system

[[ -d $systemdsystemconfdir ]] \
    || systemdsystemconfdir=$(pkg-config systemd --variable=systemdsystemconfdir 2>/dev/null)

[[ -d "$systemdsystemconfdir" ]] || systemdsystemconfdir=/etc/systemd/system

[[ -d $tmpfilesdir ]] \
    || tmpfilesdir=$(pkg-config systemd --variable=tmpfilesdir 2>/dev/null)

if ! [[ -d "$tmpfilesdir" ]]; then
    [[ -d /lib/tmpfiles.d ]] && tmpfilesdir=/lib/tmpfiles.d
    [[ -d /usr/lib/tmpfiles.d ]] && tmpfilesdir=/usr/lib/tmpfiles.d
fi

export initdir dracutbasedir \
    dracutmodules force_add_dracutmodules add_dracutmodules omit_dracutmodules \
    mods_to_load \
    fw_dir drivers_dir debug no_kernel kernel_only \
    omit_drivers mdadmconf lvmconf root_dev \
    use_fstab fstab_lines libdirs fscks nofscks ro_mnt \
    stdloglvl sysloglvl fileloglvl kmsgloglvl logfile \
    debug host_fs_types host_devs swap_devs sshkey add_fstab \
    DRACUT_VERSION udevdir prefix filesystems drivers \
    systemdutildir systemdsystemunitdir systemdsystemconfdir \
    hostonly_cmdline loginstall \
    tmpfilesdir

mods_to_load=""
# check all our modules to see if they should be sourced.
# This builds a list of modules that we will install next.
for_each_module_dir check_module
for_each_module_dir check_mount

dracut_module_included "fips" && export DRACUT_FIPS_MODE=1

do_print_cmdline()
{
    local -A _mods_to_print
    for i in $modules_loaded $mods_to_load; do
        _mods_to_print[$i]=1
    done

    # source our modules.
    for moddir in "$dracutbasedir/modules.d"/[0-9][0-9]*; do
        _d_mod=${moddir##*/}; _d_mod=${_d_mod#[0-9][0-9]}
        [[ ${_mods_to_print[$_d_mod]} ]] || continue
        module_cmdline "$_d_mod"
    done
    unset moddir
}

if [[ $print_cmdline ]]; then
    do_print_cmdline
    printf "\n"
    exit 0
fi

# Create some directory structure first
[[ $prefix ]] && mkdir -m 0755 -p "${initdir}${prefix}"

[[ -h /lib ]] || mkdir -m 0755 -p "${initdir}${prefix}/lib"
[[ $prefix ]] && ln -sfn "${prefix#/}/lib" "$initdir/lib"

if [[ $prefix ]]; then
    for d in bin etc lib sbin tmp usr var $libdirs; do
        [[ "$d" == */* ]] && continue
        ln -sfn "${prefix#/}/${d#/}" "$initdir/$d"
    done
fi

if [[ $kernel_only != yes ]]; then
    for d in usr/bin usr/sbin bin etc lib sbin tmp usr var var/tmp $libdirs; do
        [[ -e "${initdir}${prefix}/$d" ]] && continue
        if [ -L "/$d" ]; then
            inst_symlink "/$d" "${prefix}/$d"
        else
            mkdir -m 0755 -p "${initdir}${prefix}/$d"
        fi
    done

    for d in dev proc sys sysroot root run; do
        if [ -L "/$d" ]; then
            inst_symlink "/$d"
        else
            mkdir -m 0755 -p "$initdir/$d"
        fi
    done

    ln -sfn ../run "$initdir/var/run"
    ln -sfn ../run/lock "$initdir/var/lock"
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

_isize=0 #initramfs size
modules_loaded=" "
# source our modules.
for moddir in "$dracutbasedir/modules.d"/[0-9][0-9]*; do
    _d_mod=${moddir##*/}; _d_mod=${_d_mod#[0-9][0-9]}
    [[ "$mods_to_load" == *\ $_d_mod\ * ]] || continue
    if [[ $show_modules = yes ]]; then
        printf "%s\n" "$_d_mod"
    else
        dinfo "*** Including module: $_d_mod ***"
    fi
    if [[ $kernel_only == yes ]]; then
        module_installkernel "$_d_mod" || {
            dfatal "installkernel failed in module $_d_mod"
            exit 1
        }
    else
        module_install "$_d_mod"
        if [[ $no_kernel != yes ]]; then
            module_installkernel "$_d_mod" || {
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
        _isize_delta=$((_isize_new - _isize))
        printf "%s\n" "$_d_mod install size: ${_isize_delta}k"
        _isize=$_isize_new
    fi
done
unset moddir

for i in $modules_loaded; do
    mkdir -p $initdir/lib/dracut
    printf "%s\n" "$i" >> $initdir/lib/dracut/modules.txt
done

dinfo "*** Including modules done ***"

## final stuff that has to happen
if [[ $no_kernel != yes ]]; then

    if [[ $drivers ]]; then
        hostonly='' instmods $drivers
    fi

    if [[ $add_drivers ]]; then
        hostonly='' instmods -c $add_drivers
    fi
    if [[ $force_drivers ]]; then
        hostonly='' instmods -c $force_drivers
        rm -f $initdir/etc/cmdline.d/20-force_driver.conf
        for mod in $force_drivers; do
            echo "rd.driver.pre=$mod" >>$initdir/etc/cmdline.d/20-force_drivers.conf
        done
    fi
    if [[ $filesystems ]]; then
        hostonly='' instmods -c $filesystems
    fi

    dinfo "*** Installing kernel module dependencies ***"
    dracut_kernel_post
    dinfo "*** Installing kernel module dependencies done ***"

    if [[ $noimageifnotneeded == yes ]] && [[ $hostonly ]]; then
        if [[ ! -f "$initdir/lib/dracut/need-initqueue" ]] && \
            [[ -f ${initdir}/lib/modules/$kernel/modules.dep && ! -s ${initdir}/lib/modules/$kernel/modules.dep ]]; then
            for i in ${initdir}/etc/cmdline.d/*.conf; do
                # We need no initramfs image and do not generate one.
                [[ $i == "${initdir}/etc/cmdline.d/*.conf" ]] && exit 0
            done
        fi
    fi
fi

if [[ $kernel_only != yes ]]; then
    (( ${#install_items[@]} > 0 )) && inst_multiple ${install_items[@]}
    (( ${#install_optional_items[@]} > 0 )) && inst_multiple -o ${install_optional_items[@]}

    [[ $kernel_cmdline ]] && printf "%s\n" "$kernel_cmdline" >> "${initdir}/etc/cmdline.d/01-default.conf"

    for line in "${fstab_lines[@]}"; do
        line=($line)

        if [ -z "${line[1]}" ]; then
            # Determine device and mount options from current system
            mountpoint -q "${line[0]}" || derror "${line[0]} is not a mount point!"
            line=($(findmnt --raw -n --target "${line[0]}" --output=source,target,fstype,options))
            dinfo "Line for ${line[1]}: ${line[@]}"
        else
            # Use default options
            [ -z "${line[3]}" ] && line[3]="defaults"
        fi

        # Default options for freq and passno
        [ -z "${line[4]}" ] && line[4]="0"
        [ -z "${line[5]}" ] && line[5]="2"

        strstr "${line[2]}" "nfs" && line[5]="0"
        echo "${line[@]}" >> "${initdir}/etc/fstab"
    done

    for f in $add_fstab; do
        cat "$f" >> "${initdir}/etc/fstab"
    done

    if [[ $systemdutildir ]]; then
        if [ -d ${initdir}/$systemdutildir ]; then
            mkdir -p ${initdir}/etc/conf.d
            {
                printf "%s\n" "systemdutildir=\"$systemdutildir\""
                printf "%s\n" "systemdsystemunitdir=\"$systemdsystemunitdir\""
                printf "%s\n" "systemdsystemconfdir=\"$systemdsystemconfdir\""
            } > ${initdir}/etc/conf.d/systemd.conf
        fi
    fi

    if [[ $DRACUT_RESOLVE_LAZY ]] && [[ $DRACUT_INSTALL ]]; then
        dinfo "*** Resolving executable dependencies ***"
        find "$initdir" -type f -perm /0111 -not -path '*.ko' -print0 \
        | xargs -r -0 $DRACUT_INSTALL ${initdir:+-D "$initdir"} -R ${DRACUT_FIPS_MODE:+-f} --
        dinfo "*** Resolving executable dependencies done***"
    fi

    # libpthread workaround: pthread_cancel wants to dlopen libgcc_s.so
    for _dir in $libdirs; do
        for _f in "$_dir/libpthread.so"*; do
            [[ -e "$_f" ]] || continue
            inst_libdir_file "libgcc_s.so*"
            break 2
        done
    done
fi

for ((i=0; i < ${#include_src[@]}; i++)); do
    src="${include_src[$i]}"
    target="${include_target[$i]}"
    if [[ $src && $target ]]; then
        if [[ -f $src ]]; then
            inst $src $target
        else
            ddebug "Including directory: $src"
            destdir="${initdir}/${target}"
            mkdir -p "$destdir"
            # check for preexisting symlinks, so we can cope with the
            # symlinks to $prefix
            # Objectname is a file or a directory
            for objectname in "$src"/*; do
                [[ -e "$objectname" || -h "$objectname" ]] || continue
                if [[ -d "$objectname" ]]; then
                    # objectname is a directory, let's compute the final directory name
                    object_destdir=${destdir}/${objectname#$src/}
                    if ! [[ -e "$object_destdir" ]]; then
                        mkdir -m 0755 -p "$object_destdir"
                        chmod --reference="$objectname" "$object_destdir"
                    fi
                    cp --reflink=auto --sparse=auto -fa -t "$object_destdir" "$objectname"/*
                else
                    cp --reflink=auto --sparse=auto -fa -t "$destdir" "$objectname"
                fi
            done
        fi
    fi
done

if [[ $kernel_only != yes ]]; then
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

PRELINK_BIN="$(command -v prelink)"
if [[ $UID = 0 ]] && [[ $PRELINK_BIN ]]; then
    if [[ $DRACUT_FIPS_MODE ]]; then
        dinfo "*** Installing prelink files ***"
        inst_multiple -o prelink /etc/prelink.conf /etc/prelink.conf.d/*.conf /etc/prelink.cache
    elif [[ $do_prelink == yes ]]; then
        dinfo "*** Pre-linking files ***"
        inst_multiple -o prelink /etc/prelink.conf /etc/prelink.conf.d/*.conf
        chroot "$initdir" "$PRELINK_BIN" -a
        rm -f -- "$initdir/$PRELINK_BIN"
        rm -fr -- "$initdir"/etc/prelink.*
        dinfo "*** Pre-linking files done ***"
    fi
fi

if [[ $do_hardlink = yes ]] && command -v hardlink >/dev/null; then
    dinfo "*** Hardlinking files ***"
    hardlink "$initdir" 2>&1
    dinfo "*** Hardlinking files done ***"
fi

# strip binaries
if [[ $do_strip = yes ]] ; then
    for p in strip xargs find; do
        if ! type -P $p >/dev/null; then
            dinfo "Could not find '$p'. Not stripping the initramfs."
            do_strip=no
        fi
    done
fi

if [[ $do_strip = yes ]] && ! [[ $DRACUT_FIPS_MODE ]]; then
    dinfo "*** Stripping files ***"
    find "$initdir" -type f \
        -executable -not -path '*/lib/modules/*.ko' -print0 \
        | xargs -r -0 strip -g 2>/dev/null

    # strip kernel modules, but do not touch signed modules
    find "$initdir" -type f -path '*/lib/modules/*.ko' -print0 \
        | while read -r -d $'\0' f || [ -n "$f" ]; do
        SIG=$(tail -c 28 "$f")
        [[ $SIG == '~Module signature appended~' ]] || { printf "%s\000" "$f"; }
    done | xargs -r -0 strip -g

    dinfo "*** Stripping files done ***"
fi
if [[ $early_microcode = yes ]]; then
    dinfo "*** Generating early-microcode cpio image ***"
    ucode_dir=(amd-ucode intel-ucode)
    ucode_dest=(AuthenticAMD.bin GenuineIntel.bin)
    _dest_dir="$early_cpio_dir/d/kernel/x86/microcode"
    _dest_idx="0 1"
    mkdir -p $_dest_dir
    if [[ $hostonly ]]; then
        [[ $(get_cpu_vendor) == "AMD" ]] && _dest_idx="0"
        [[ $(get_cpu_vendor) == "Intel" ]] && _dest_idx="1"
    fi
    for idx in $_dest_idx; do
        _fw=${ucode_dir[$idx]}
        for _fwdir in $fw_dir; do
            if [[ -d $_fwdir && -d $_fwdir/$_fw ]]; then
                _src="*"
                dinfo "*** Constructing ${ucode_dest[$idx]} ****"
                if [[ $hostonly ]]; then
                    _src=$(get_ucode_file)
                    [[ $_src ]] || break
                    [[ -r $_fwdir/$_fw/$_src ]] || break
                fi

                for i in $_fwdir/$_fw/$_src; do
                    [ -e "$i" ] && break
                    break 2
                done
                for i in $_fwdir/$_fw/$_src; do
                    [[ -e "$i" ]] || continue
                    # skip gpg files
                    str_ends "$i" ".asc" && continue
                    cat "$i" >> $_dest_dir/${ucode_dest[$idx]}
                done
                create_early_cpio="yes"
            fi
        done
    done
fi

if [[ $acpi_override = yes ]] && [[ -d $acpi_table_dir ]]; then
    dinfo "*** Packaging ACPI tables to override BIOS provided ones ***"
    _dest_dir="$early_cpio_dir/d/kernel/firmware/acpi"
    mkdir -p $_dest_dir
    for table in $acpi_table_dir/*.aml; do
        dinfo "   Adding ACPI table: $table"
        cp -a $table $_dest_dir
        create_early_cpio="yes"
    done
fi

dinfo "*** Store current command line parameters ***"
if ! ( echo $PARMS_TO_STORE > $initdir/lib/dracut/build-parameter.txt ); then
    dfatal "Could not store the current command line parameters"
    exit 1
fi

if [[ $hostonly_cmdline ]] ; then
    unset _stored_cmdline
    if [ -d $initdir/etc/cmdline.d ];then
        dinfo "Stored kernel commandline:"
        for conf in $initdir/etc/cmdline.d/*.conf ; do
            [ -e "$conf" ] || continue
            dinfo "$(< $conf)"
            _stored_cmdline=1
        done
    fi
    if ! [[ $_stored_cmdline ]]; then
        dinfo "No dracut internal kernel commandline stored in the initramfs"
    fi
fi

dinfo "*** Creating image file '$outfile' ***"

if [[ $uefi = yes ]]; then
    readonly uefi_outdir="$DRACUT_TMPDIR/uefi"
    mkdir "$uefi_outdir"
fi

if [[ $DRACUT_REPRODUCIBLE ]]; then
    find "$initdir" -newer "$dracutbasedir/dracut-functions.sh" -print0 \
        | xargs -r -0 touch -h -m -c -r "$dracutbasedir/dracut-functions.sh"

    if [[ "$(cpio --help)" == *--reproducible* ]]; then
        CPIO_REPRODUCIBLE=1
    else
        dinfo "cpio does not support '--reproducible'. Resulting image will not be reproducible."
    fi
fi

[[ "$UID" != 0 ]] && cpio_owner_root="-R 0:0"

if [[ $create_early_cpio = yes ]]; then
    echo 1 > "$early_cpio_dir/d/early_cpio"

    if [[ $DRACUT_REPRODUCIBLE ]]; then
        find "$early_cpio_dir/d" -newer "$dracutbasedir/dracut-functions.sh" -print0 \
            | xargs -r -0 touch -h -m -c -r "$dracutbasedir/dracut-functions.sh"
    fi

    # The microcode blob is _before_ the initramfs blob, not after
    if ! (
            umask 077; cd "$early_cpio_dir/d"
            find . -print0 | sort -z \
                | cpio ${CPIO_REPRODUCIBLE:+--reproducible} --null $cpio_owner_root -H newc -o --quiet > "${DRACUT_TMPDIR}/initramfs.img"
        ); then
        dfatal "dracut: creation of $outfile failed"
        exit 1
    fi
fi

if ! (
        umask 077; cd "$initdir"
        find . -print0 | sort -z \
            | cpio ${CPIO_REPRODUCIBLE:+--reproducible} --null $cpio_owner_root -H newc -o --quiet \
            | $compress >> "${DRACUT_TMPDIR}/initramfs.img"
    ); then
    dfatal "dracut: creation of $outfile failed"
    exit 1
fi

if (( maxloglvl >= 5 )); then
    if [[ $allowlocal ]]; then
	"$dracutbasedir/lsinitrd.sh" "${DRACUT_TMPDIR}/initramfs.img"| ddebug
    else
        lsinitrd "${DRACUT_TMPDIR}/initramfs.img"| ddebug
    fi
fi

umask 077

if [[ $uefi = yes ]]; then
    if [[ $kernel_cmdline ]]; then
        echo -n "$kernel_cmdline" > "$uefi_outdir/cmdline.txt"
    elif [[ $hostonly_cmdline = yes ]] && [ -d $initdir/etc/cmdline.d ];then
        for conf in $initdir/etc/cmdline.d/*.conf ; do
            [ -e "$conf" ] || continue
            printf "%s " "$(< $conf)" >> "$uefi_outdir/cmdline.txt"
        done
    else
        do_print_cmdline > "$uefi_outdir/cmdline.txt"
    fi
    echo -ne "\x00" >> "$uefi_outdir/cmdline.txt"

    dinfo "Using UEFI kernel cmdline:"
    dinfo $(< "$uefi_outdir/cmdline.txt")

    [[ -s /usr/lib/os-release ]] && uefi_osrelease="/usr/lib/os-release"
    [[ -s /etc/os-release ]] && uefi_osrelease="/etc/os-release"

    if objcopy \
           ${uefi_osrelease:+--add-section .osrel=$uefi_osrelease --change-section-vma .osrel=0x20000} \
           --add-section .cmdline="${uefi_outdir}/cmdline.txt" --change-section-vma .cmdline=0x30000 \
           --add-section .linux="$kernel_image" --change-section-vma .linux=0x40000 \
           --add-section .initrd="${DRACUT_TMPDIR}/initramfs.img" --change-section-vma .initrd=0x3000000 \
           "$uefi_stub" "${uefi_outdir}/linux.efi" \
            && cp --reflink=auto "${uefi_outdir}/linux.efi" "$outfile"; then
        dinfo "*** Creating UEFI image file '$outfile' done ***"
    else
        rm -f -- "$outfile"
        dfatal "*** Creating UEFI image file '$outfile' failed ***"
        exit 1
    fi
else
    if cp --reflink=auto "${DRACUT_TMPDIR}/initramfs.img" "$outfile"; then
        dinfo "*** Creating initramfs image file '$outfile' done ***"
    else
        rm -f -- "$outfile"
        dfatal "dracut: creation of $outfile failed"
        exit 1
    fi
fi

command -v restorecon &>/dev/null && restorecon -- "$outfile"

exit 0
