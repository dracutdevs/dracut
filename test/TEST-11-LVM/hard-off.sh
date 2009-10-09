#!/bin/sh
getarg rdshell || poweroff -f
getarg failme && poweroff -f
