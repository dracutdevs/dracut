#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# This meta module is called from dracut.

check() {

    depends
    # We only want to return 255 since this is a meta module.
    return 255

}

depends() {

    local _sh _shells _shells_pattern

    # Assure an explicitly installed command shell.

    # An alternative command shell may be specified by adding a module to
    # ../dracut/modules.d/ and linking its executable to /bin/sh of the host.
    _sh=$(realpath -e /bin/sh)
    _sh=${_sh##*/}
    _shells='dash bash mksh busybox ~no~sh'
    strstr " $_shells " " $_sh " || _shells="${_sh:+$_sh }$_shells"

    for _sh in $_shells; do
        _shells_pattern+="* $_sh *|"
    done

    strstr " $mods_to_load " " ~no~sh " && {
        # If a shell is queued (explicitly or by a module level dependency,
        # but not an executable dependency), then ignore ~no~sh.
        # ~no~sh masks executable dependencies for /bin/sh.
        [[ ${mods_to_load/ ~no~sh/} == @(${_shells_pattern%|}) ]] && {
            mods_to_load=${mods_to_load/ ~no~sh/}
            mods_to_postprocess=${mods_to_postprocess/ ~no~sh:* /}
        }
    }

    [[ " $mods_to_load " == @(${_shells_pattern%|}) ]] || {
        for _sh in $_shells; do
            add_dracutmodules+=" $_sh "
            check_module "$_sh"
            [[ $? == @(0|255) ]] || {
                add_dracutmodules=${add_dracutmodules/" $_sh "/}
                continue
            }
            [[ $dracutmodules == all ]] && echo "$_sh"
            # We only want to return 255 since this is a meta module.
            return 255
        done
        dfatal "One of the command shells, '$_shells', must be made available."
        exit 1
    }
    # We only want to return 255 since this is a meta module.
    return 255
}
