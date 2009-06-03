#!/bin/sh

if [ -x /bin/plymouth ]; then
  /bin/plymouth --show-splash
  /bin/plymouth --newroot=$NEWROOT
fi
