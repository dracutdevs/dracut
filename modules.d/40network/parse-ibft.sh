#!/bin/sh

command -v getarg >/dev/null          || . /lib/dracut-lib.sh
command -v ibft_to_cmdline >/dev/null || . /lib/net-lib.sh

if getargbool 0 rd.iscsi.ibft -d "ip=ibft"; then
    ibft_to_cmdline
fi
