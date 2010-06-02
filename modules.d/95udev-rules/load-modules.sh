#!/bin/sh
# Implement blacklisting for udev-loaded modules

modprobe -b "$@"

# vim: set et ts=4:
