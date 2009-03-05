#!/bin/sh
dmraid -ay
udevadm settle --timeout=30 >/dev/null 2>&1 

