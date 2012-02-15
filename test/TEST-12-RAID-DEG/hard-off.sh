#!/bin/sh
getarg rd.shell || poweroff -f
! getarg rd.break && getarg failme && poweroff -f
