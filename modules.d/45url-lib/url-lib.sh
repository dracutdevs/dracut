#!/bin/sh
# url-lib.sh - functions for handling URLs (file fetching etc.)
#
# Authors:
#   Will Woods <wwoods@redhat.com>

type mkuniqdir >/dev/null 2>&1 || . /lib/dracut-lib.sh

# fetch_url URL [OUTFILE]
#   fetch the given URL to a locally-visible location.
#   if OUTFILE is given, the URL will be fetched to that filename,
#   overwriting it if present.
#   If the URL is something mountable (e.g. nfs://) and no OUTFILE is given,
#   the server will be left mounted until pre-pivot.
#   the return values are as follows:
#   0: success
#   253: unknown error (file missing)
#   254: unhandled URL scheme / protocol
#   255: bad arguments / unparseable URLs
#   other: fetch command failure (whatever curl/mount/etc return)
fetch_url() {
    local url="$1" outloc="$2"
    local handler="$(get_url_handler $url)"
    [ -n "$handler" ] || return 254
    [ -n "$url" ] || return 255
    $handler "$url" "$outloc"
}

# get_url_handler URL
#   returns the first HANDLERNAME corresponding to the URL's scheme
get_url_handler() {
    local scheme="${1%%:*}" item=""
    for item in $url_handler_map; do
        [ "$scheme" = "${item%%:*}" ] && echo "${item#*:}" && return 0
    done
    return 1
}

# add_url_handler HANDLERNAME SCHEME [SCHEME...]
#   associate the named handler with the named scheme(s).
add_url_handler() {
    local handler="$1"; shift
    local schemes="$@" scheme=""
    set --
    for scheme in $schemes; do
        set -- "$@" "$scheme:$handler"
    done
    set -- $@ $url_handler_map # add new items to *front* of list
    url_handler_map="$@"
}

### HTTP, HTTPS, FTP #################################################

export CURL_HOME="/run/initramfs/url-lib"
mkdir -p $CURL_HOME
curl_args="--location --retry 3 --fail --show-error"
curl_fetch_url() {
    local url="$1" outloc="$2"
    if [ -n "$outloc" ]; then
        curl $curl_args --output "$outloc" "$url" || return $?
    else
        local outdir="$(mkuniqdir /tmp curl_fetch_url)"
        ( cd "$outdir"; curl $curl_args --remote-name "$url" || return $? )
        outloc="$outdir/$(ls -A $outdir)"
    fi
    [ -f "$outloc" ] || return 253
    echo "$outloc"
}
add_url_handler curl_fetch_url http https ftp

set_http_header() {
    echo "header = \"$1: $2\"" >> $CURL_HOME/.curlrc
}

### NFS ##############################################################

. /lib/nfs-lib.sh

nfs_already_mounted() {
    local server="$1" path="$2" localdir="" s="" p=""
    cat /proc/mounts | while read src mnt rest; do
        splitsep ":" "$src" s p
        if [ "$server" = "$s" ]; then
            if [ "$path" = "$p" ]; then
                echo $mnt
            elif str_starts "$path" "$p"; then
                echo $mnt/${path#$p/}
            fi
        fi
    done
}

nfs_fetch_url() {
    local url="$1" outloc="$2" nfs="" server="" path="" options=""
    nfs_to_var "$url" || return 255
    local filepath="${path%/*}" filename="${path##*/}" mntdir=""

    # skip mount if server:/filepath is already mounted
    mntdir=$(nfs_already_mounted $server $path)
    if [ -z "$mntdir" ]; then
        local mntdir="$(mkuniqdir /run nfs_mnt)"
        mount_nfs $nfs:$server:$path${options:+:$options} $mntdir
        # lazy unmount during pre-pivot hook
        inst_hook --hook pre-pivot --name 99url-lib-umount-nfs umount -l $mntdir
    fi

    if [ -z "$outloc" ]; then
        outloc="$mntdir/$filename"
    else
        cp -f "$mntdir/$filename" "$outloc" || return $?
    fi
    [ -f "$outloc" ] || return 253
    echo "$outloc"
}
add_url_handler nfs_fetch_url nfs nfs4
