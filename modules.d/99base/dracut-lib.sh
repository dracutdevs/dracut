getarg() {
    local o line
    [ "$CMDLINE" ] || read CMDLINE </proc/cmdline;
    for o in $CMDLINE; do
	[ "$o" = "$1" ] && return 0
	[ "${o%%=*}" = "${1%=}" ] && { echo ${o#*=}; return 0; }
    done
    return 1
}

getargs() {
    local o line found
    [ "$CMDLINE" ] || read CMDLINE </proc/cmdline;
    for o in $CMDLINE; do
	[ "$o" = "$1" ] && return 0
	if [ "${o%%=*}" = "${1%=}" ]; then
	    echo -n "${o#*=} "; 
	    found=1;
	fi
    done
    [ -n "$found" ] && return 0
    return 1
}

source_all() {
    local f
    [ "$1" ] && [  -d "/$1" ] || return
    for f in "/$1"/*.sh; do [ -f "$f" ] && . "$f"; done
}

die() {
    printf "<1>FATAL: $1\n" > /dev/kmsg
    printf "<1>Refusing to continue\n" > /dev/kmsg
    exit 1
}

warn() {
    printf "<1>Warning: $1\n" > /dev/kmsg
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
