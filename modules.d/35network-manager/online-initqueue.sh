#!/bin/bash

type nm_call_hooks > /dev/null 2>&1 || . /lib/nm-lib.sh

ifname="$1"
action="$2"

[ "${action}" = "up" ] || exit 0

. /dracut-state.sh

nm_call_hooks "$ifname"
