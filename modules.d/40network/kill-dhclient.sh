#!/bin/sh

pid=$(pidof dhclient)
[ -n "$pid" ] && kill $pid
