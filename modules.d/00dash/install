#!/bin/bash
# Prefer dash as /bin/sh if it is available.
if [[ -f /bin/dash ]]; then
    inst /bin/dash
    ln -sf /bin/dash "${initdir}/bin/sh"
fi