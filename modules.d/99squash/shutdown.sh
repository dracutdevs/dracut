#!/bin/sh
/squash/setup-squash.sh

exec /shutdown.stock

echo "Something went wrong when trying to start original shutdown executable!"
exit 1
