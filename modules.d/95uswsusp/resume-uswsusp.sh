#!/bin/sh
case "$splash" in
    quiet )
	a_splash="-P splash=y"
    ;;
    * )
	a_splash="-P splash=n"
    ;;
esac

/usr/sbin/resume $a_splash "$resume"
