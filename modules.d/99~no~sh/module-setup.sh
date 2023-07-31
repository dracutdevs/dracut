#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# This meta module is included when no command shell is desired.

check() {

    # We only want to return 255 since this is a meta module.
    return 255

}

install() {

    # Enroll module for postprocessing.
    mods_to_postprocess+=" ~no~sh:$moddir@installpost@ "

    # Installing a null link satisfies the executable dependency check.
    ln -sf ../../dev/null "${initdir}"/bin/sh

}

postprocess() {

    [[ $action == installpost ]] && {
        # Remove the faked installation link.
        rm "${initdir}"/usr/bin/sh
        return $?
    }
    return 0
}
