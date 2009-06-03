#!/bin/sh

if [ -x /bin/plymouth ]; then
  /bin/plymouth --newroot=$NEWROOT
fi
