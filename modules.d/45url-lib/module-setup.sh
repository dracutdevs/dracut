#!/bin/sh

# called by dracut
check() {
    require_binaries curl || return 1
    return 255
}

# called by dracut
depends() {
    echo network
    return 0
}

# called by dracut
install() {
    local _dir _crt _crts _found _lib _nssckbi
    inst_simple "$moddir/url-lib.sh" "/lib/url-lib.sh"
    inst_multiple -o ctorrent
    inst_multiple curl sed
    if curl --version | grep -qwiF 'NSS'; then
        # also install libs for curl https
        inst_libdir_file "libnsspem.so*"
        inst_libdir_file "libnsssysinit.so*"
        inst_libdir_file "libsoftokn3.so*"
        inst_libdir_file "libsqlite3.so*"
    fi

    for _dir in $libdirs; do
        [ -d "$dracutsysrootdir$_dir" ] || continue
        for _lib in "$dracutsysrootdir$_dir"/libcurl.so.* "$dracutsysrootdir$_dir"/libcrypto.so.*; do
            [ -e "$_lib" ] || continue
            [ -z "$_nssckbi" ] && grep -Fqaz libnssckbi "$_lib" && _nssckbi=1
            _crt="$(grep -Eazm1 "\.(pem|crt)" "$_lib" | tr -d '\0')"
            [ "${_crt#/*/}" != "$_crt" ] || continue
            if [ -e "$_crt" ]; then
                _crts="$_crts $_crt"
                _found=1
            fi
        done
    done
    if [ -n "$_found" ]; then
        for _crt in $_crts; do
            inst "${_crt#"$dracutsysrootdir"}" || dwarn "Couldn't install '$_crt' SSL CA cert bundle; HTTPS might not work."
        done
    fi
    # If we found no cert bundle files referenced in libcurl but we
    # *did* find a mention of libnssckbi (checked above), install it.
    # If its truly NSS libnssckbi, it includes its own trust bundle,
    # but if it's really p11-kit-trust.so, we need to find the dirs
    # where it will look for a trust bundle and install them too.
    if [ -z "$_found" ] && [ -n "$_nssckbi" ]; then
        inst_libdir_file "libnssckbi.so*" && _found=1 || _found=
        for _dir in $libdirs; do
            [ -e "$dracutsysrootdir$_dir"/libnssckbi.so ] || continue
            # this looks for directory-ish strings in the file
            grep -zoa '/[[:alpha:]][[:print:]]*' "$dracutsysrootdir$_dir"/libnssckbi.so \
                | tr '\0' '\n' | while read -r _p11roots || [ -n "$_p11roots" ]; do
                IFS=:
                # the string can be a :-separated list of dirs
                for _p11root in $_p11roots; do
                    # check if it's actually a directory (there are
                    # several false positives in the results)
                    [ -d "$dracutsysrootdir$_p11root" ] || continue
                    # check if it has some specific subdirs that all
                    # p11-kit trust dirs have
                    [ -d "$dracutsysrootdir$_p11root/anchors" ] || continue
                    [ -d "$dracutsysrootdir$_p11root/blacklist" ] || continue
                    # so now we know it's really a p11-kit trust dir;
                    # install everything in it
                    mkdir -p -- "${initdir}/${_p11root}"
                    if ! $DRACUT_CP -L -t "${initdir}/${_p11root}" "$dracutsysrootdir$_p11root"/*; then
                        dwarn "Couldn't install from p11-kit trust dir '${_p11root#"$dracutsysrootdir"}'; HTTPS might not work."
                    fi
                done
            done
        done
    fi
    [ -n "$_found" ] || dwarn "Couldn't find SSL CA cert bundle or libnssckbi.so; HTTPS won't work."
}
