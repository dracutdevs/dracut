#!/bin/sh
N=${1:-1}
exec setterm -term linux -dump "$N" -file /proc/self/fd/1
