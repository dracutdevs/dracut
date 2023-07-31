#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # Enroll module for postprocessing.
    strstr " $mods_to_postprocess " " bash:$moddir@installpost@ " || {
        mods_to_postprocess+=" bash:$moddir@installpost@ "
    }

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries bash || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst /bin/bash

    # Prefer bash as default shell if no other shell is preferred.
    [[ -L $initdir/bin/sh ]] || ln -sf bash "${initdir}/bin/sh"

}

# Execute any postprocessing requirements.
postprocess() {

    [[ $action == installpost ]] && {
        [[ $(readlink "${initdir}"/bin/sh) == bash ]] && {
            local version ver0 ver1

            # local - (available since bash-4.4 2016-09-15) automates the
            #         restoration of local xtrace & other set options.
            IFS=' ' read -r -a version <<< "$(command /bin/bash --version)"
            IFS=. read -r ver0 ver1 _ <<< "${version[3]}"
            if ((${ver0}${ver1} < 44)); then
                dfatal "Installed Bash ${version[3]} ${version[4]}.
        At least Bash 4.4 is required for proper xtrace logging
        when Bash is the initramfs command shell."
                exit 1
            fi
        }
    }
    return 0
}
