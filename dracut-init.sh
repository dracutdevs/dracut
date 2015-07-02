#!/bin/bash
#
# functions used by dracut and other tools.
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

if [[ $DRACUT_KERNEL_LAZY ]] && ! [[ $DRACUT_KERNEL_LAZY_HASHDIR ]]; then
    if ! [[ -d "$initdir/.kernelmodseen" ]]; then
        mkdir -p "$initdir/.kernelmodseen"
    fi
    DRACUT_KERNEL_LAZY_HASHDIR="$initdir/.kernelmodseen"
fi

if [[ $initdir ]] && ! [[ -d $initdir ]]; then
    mkdir -p "$initdir"
fi

[[ $dracutbasedir ]] || export dracutbasedir=${BASH_SOURCE%/*}
. $dracutbasedir/dracut-functions.sh
