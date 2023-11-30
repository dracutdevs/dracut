#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

getargbool 0 rd.udev.debug -d -y rdudevdebug && cat > "$1" <<EOF
[Service]
LogLevelMax=debug
EOF
