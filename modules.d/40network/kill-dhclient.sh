#!/bin/sh

pid=$(pidof dhclient)
[[ $pid ]] && kill $pid
