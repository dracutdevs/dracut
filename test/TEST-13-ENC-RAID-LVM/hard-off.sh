#!/bin/sh
getarg rdinitdebug || poweroff -f
getarg failme && poweroff -f
