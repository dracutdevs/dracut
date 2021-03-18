#!/bin/sh

if [ "${root%%:*}" = "virtfs" ]; then
    modprobe 9pnet_virtio

    # shellcheck disable=SC2034
    rootok=1
fi
