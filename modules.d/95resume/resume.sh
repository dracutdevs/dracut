#!/bin/sh
[ -s /.resume -a -b "$resume" ] && {
    # parsing the output of ls is Bad, but until there is a better way...
    ls -lH "$resume" | ( 
	read x x x x maj min x;
	echo "${maj%,}:$min"> /sys/power/resume)
    >/.resume
}
