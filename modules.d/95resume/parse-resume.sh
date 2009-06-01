#!/bin/sh
if resume=$(getarg resume=) && ! getarg noresume; then 
    export resume
    echo "$resume" >/.resume
else
    unset resume
fi

case "$resume" in
    LABEL=*)
	resume="$(echo $resume | sed 's,/,\\x2f,g')"
	resume="/dev/disk/by-label/${resume#LABEL=}" ;;
    UUID=*)
	resume="/dev/disk/by-uuid/${resume#UUID=}" ;;
esac
