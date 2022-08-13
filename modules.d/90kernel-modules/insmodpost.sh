#!/bin/sh

. /lib/dracut-lib.sh

IFS="$IFS,"
# shellcheck disable=SC2046
modprobe -a $(getargs rd.driver.post -d rdinsmodpost=)
