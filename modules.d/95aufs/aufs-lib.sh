#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# aufs_to_var AUFSROOT
# use AUFSROOT to set $rwbranch, $robranch, and $options.
# AUFSROOT is something like: aufs:<rwbranch>:<robranch>[,<options>]

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

aufs_to_var() {
	local branches

	branches=${1##aufs:}
	branches=${branches%%,*}
	aufsrwbranch=${branches%%:*}
	aufsrobranch=${branches##*:}

	aufsoptions=${1#*,}
}
