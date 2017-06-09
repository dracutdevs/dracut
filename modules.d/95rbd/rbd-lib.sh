#!/bin/sh

# parse rbdroot into variables
parse_rbdroot()
{
    local rbdroot="$1"
    local IFS=":"
    i=1
    for arg in $rbdroot ; do
        case $i in
            1) mons=$arg
                ;;
            2) user=$arg
                ;;
            3) key=$arg
                ;;
            4) pool=$arg
                ;;
            # image contains an @, i.e. a snapshot
            5)  if [ ${arg#*@*} != ${arg} ] ; then
                    image=${arg%%@*}
                    snap=${arg##*@}
                else
                    image=$arg
                    snap=""
                fi
                ;;
            6) partition=$arg
                ;;
            7) opts=$arg
                ;;
        esac
        i=$(($i + 1))
    done
}
