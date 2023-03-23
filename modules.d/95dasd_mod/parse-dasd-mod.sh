#!/bin/sh
if [ -x /sbin/dasd_cio_free ]; then
    dasd_cio_free
fi
