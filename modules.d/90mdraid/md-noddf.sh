#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
info "rd.md.ddf=0: no MD RAID for SNIA ddf raids"
udevproperty rd_NO_MDDDF=1
