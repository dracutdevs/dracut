#!/bin/sh
{
    flock -e 9
    iscsistart "$@"
} 9>/tmp/.iscsi_lock
