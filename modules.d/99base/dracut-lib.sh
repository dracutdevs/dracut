
# returns OK if $1 contains $2
strstr() {
  [ "${1#*$2*}" != "$1" ]
}

getarg() {
    set +x 
    local o line val
    if [ -z "$CMDLINE" ]; then
        if [ -e /etc/cmdline ]; then
            while read line; do
                CMDLINE_ETC="$CMDLINE_ETC $line";
            done </etc/cmdline;
        fi
	read CMDLINE </proc/cmdline;
	CMDLINE="$CMDLINE $CMDLINE_ETC"
    fi
    for o in $CMDLINE; do
	if [ "$o" = "$1" ]; then
            [ "$RDDEBUG" = "yes" ] && set -x; 
	    return 0; 
        fi
        [ "${o%%=*}" = "${1%=}" ] && val=${o#*=};
    done
    if [ -n "$val" ]; then
        echo $val; 
        [ "$RDDEBUG" = "yes" ] && set -x; 
	return 0;
    fi
    [ "$RDDEBUG" = "yes" ] && set -x 
    return 1
}

getargs() {
    set +x 
    local o line found
    if [ -z "$CMDLINE" ]; then
	if [ -e /etc/cmdline ]; then
            while read line; do
                CMDLINE_ETC="$CMDLINE_ETC $line";
            done </etc/cmdline;
        fi
	read CMDLINE </proc/cmdline;
	CMDLINE="$CMDLINE $CMDLINE_ETC"
    fi
    for o in $CMDLINE; do
	if [ "$o" = "$1" ]; then
             [ "$RDDEBUG" = "yes" ] && set -x; 
	     return 0;
	fi
	if [ "${o%%=*}" = "${1%=}" ]; then
	    echo -n "${o#*=} "; 
	    found=1;
	fi
    done
    if [ -n "$found" ]; then
        [ "$RDDEBUG" = "yes" ] && set -x
	return 0;
    fi
    [ "$RDDEBUG" = "yes" ] && set -x 
    return 1;
}

# Prints value of given option.  If option is a flag and it's present,
# it just returns 0.  Otherwise 1 is returned.
# $1 = options separated by commas
# $2 = option we are interested in
# 
# Example:
# $1 = cipher=aes-cbc-essiv:sha256,hash=sha256,verify
# $2 = hash
# Output:
# sha256
getoptcomma() {
    local line=",$1,"; local opt="$2"; local tmp

    case "${line}" in
        *,${opt}=*,*)
            tmp="${line#*,${opt}=}"
            echo "${tmp%%,*}"
            return 0
        ;;
        *,${opt},*) return 0 ;;
    esac

    return 1
}

setdebug() {
    if [ -z "$RDDEBUG" ]; then
        if [ -e /proc/cmdline ]; then
            RDDEBUG=no
            if getarg rdinitdebug || getarg rdnetdebug; then
                RDDEBUG=yes 
            fi
        fi
	export RDDEBUG
    fi
    [ "$RDDEBUG" = "yes" ] && set -x 
}

setdebug

source_all() {
    local f
    [ "$1" ] && [  -d "/$1" ] || return
    for f in "/$1"/*.sh; do [ -e "$f" ] && . "$f"; done
}

check_finished() {
    local f
    for f in /initqueue-finished/*.sh; do { [ -e "$f" ] && ( . "$f" ) ; } || return 1 ; done
    return 0
}

source_conf() {
    local f
    [ "$1" ] && [  -d "/$1" ] || return
    for f in "/$1"/*.conf; do [ -e "$f" ] && . "$f"; done
}

die() {
    {
        echo "<1>dracut: FATAL: $@";
        echo "<1>dracut: Refusing to continue";
    } > /dev/kmsg

    { 
        echo "dracut: FATAL: $@";
        echo "dracut: Refusing to continue";
    } >&2
    
    exit 1
}

check_quiet() {
    if [ -z "$DRACUT_QUIET" ]; then
	DRACUT_QUIET="yes"
	getarg rdinfo && DRACUT_QUIET="no"
	getarg quiet || DRACUT_QUIET="yes"
    fi
}

warn() {
    check_quiet
    echo "<4>dracut Warning: $@" > /dev/kmsg
    [ "$DRACUT_QUIET" != "yes" ] && \
    	echo "dracut Warning: $@" >&2
}

info() {
    check_quiet
    echo "<6>dracut: $@" > /dev/kmsg
    [ "$DRACUT_QUIET" != "yes" ] && \
	echo "dracut: $@" 
}

vinfo() {
    while read line; do 
        info $line;
    done
}

check_occurances() {
    # Count the number of times the character $ch occurs in $str
    # Return 0 if the count matches the expected number, 1 otherwise
    local str="$1"
    local ch="$2"
    local expected="$3"
    local count=0

    while [ "${str#*$ch}" != "${str}" ]; do
	str="${str#*$ch}"
	count=$(( $count + 1 ))
    done

    [ $count -eq $expected ]
}

incol2() {
    local dummy check;
    local file="$1";
    local str="$2";

    [ -z "$file" ] && return;
    [ -z "$str"  ] && return;

    while read dummy check restofline; do
	[ "$check" = "$str" ] && return 0
    done < $file
    return 1
}

udevsettle() {
    [ -z "$UDEVVERSION" ] && UDEVVERSION=$(udevadm --version)

    if [ $UDEVVERSION -ge 143 ]; then
        udevadm settle --exit-if-exists=/initqueue/work $settle_exit_if_exists
    else
        udevadm settle --timeout=30
    fi
}

udevproperty() {
    [ -z "$UDEVVERSION" ] && UDEVVERSION=$(udevadm --version)

    if [ $UDEVVERSION -ge 143 ]; then
	for i in "$@"; do udevadm control --property=$i; done
    else
	for i in "$@"; do udevadm control --env=$i; done
    fi
}

wait_for_if_up() {
    local cnt=0
    while [ $cnt -lt 20 ]; do 
	li=$(ip link show $1)
	[ -z "${li##*state UP*}" ] && return 0
	sleep 0.1
	cnt=$(($cnt+1))
    done 
    return 1
}

# root=nfs:[<server-ip>:]<root-dir>[:<nfs-options>] 
# root=nfs4:[<server-ip>:]<root-dir>[:<nfs-options>]
nfsroot_to_var() {
    # strip nfs[4]:
    local arg="$@:"
    nfs="${arg%%:*}"
    arg="${arg##$nfs:}"

    # check if we have a server
    if strstr "$arg" ':/*' ; then
	server="${arg%%:/*}"
	arg="/${arg##*:/}"
    fi

    path="${arg%%:*}"

    # rest are options
    options="${arg##$path}"
    # strip leading ":"
    options="${options##:}"
    # strip  ":"
    options="${options%%:}"
    
    # Does it really start with '/'?
    [ -n "${path%%/*}" ] && path="error";
    
    #Fix kernel legacy style separating path and options with ','
    if [ "$path" != "${path#*,}" ] ; then
	options=${path#*,}
	path=${path%%,*}
    fi
}

ip_to_var() {
    local v=${1}:
    local i
    set -- 
    while [ -n "$v" ]; do
	if [ "${v#\[*:*:*\]:}" != "$v" ]; then
	    # handle IPv6 address
	    i="${v%%\]:*}"
	    i="${i##\[}"
	    set -- "$@" "$i"
	    v=${v#\[$i\]:}
	else		    
	    set -- "$@" "${v%%:*}"
	    v=${v#*:}
	fi
    done

    unset ip srv gw mask hostname dev autoconf
    case $# in
    0)	autoconf="error" ;;
    1)	autoconf=$1 ;;
    2)	dev=$1; autoconf=$2 ;;
    *)	ip=$1; srv=$2; gw=$3; mask=$4; hostname=$5; dev=$6; autoconf=$7 ;;
    esac
}

# Evaluate command for UUIDs either given as arguments for this function or all
# listed in /dev/disk/by-uuid.  UUIDs doesn't have to be fully specified.  If
# beginning is given it is expanded to all matching UUIDs.  To pass full UUID
# to your command use '${full_uuid}'.  Remember to escape '$'!
#
# $1 = command to be evaluated
# $2 = list of UUIDs separated by space
#
# The function returns after *first successful evaluation* of the given command
# with status 0.  If evaluation fails for every UUID function returns with
# status 1.
#
# Example:
# foreach_uuid_until "mount -U \${full_uuid} /mnt; echo OK; umount /mnt" \
#       "01234 f512 a235567f-12a3-c123-a1b1-01234567abcb"
foreach_uuid_until() (
    cd /dev/disk/by-uuid

    local cmd="$1"; shift; local uuids_list="$*"
    local uuid; local full_uuid

    [ -n "${cmd}" ] || return 1

    for uuid in ${uuids_list:-*}; do
        for full_uuid in ${uuid}*; do
            [ -e "${full_uuid}" ] || continue
            eval ${cmd} && return 0
        done
    done

    return 1
)
