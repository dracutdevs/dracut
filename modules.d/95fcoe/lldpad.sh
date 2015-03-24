#!/bin/bash

# Note lldpad will stay running after switchroot, the system initscripts
# are to kill it and start a new lldpad to take over. Data is transfered
# between the 2 using a shm segment
lldpad -d
# wait for lldpad to be ready
i=0
while [ $i -lt 60 ]; do
    lldptool -p && break
    info "Waiting for lldpad to be ready"
    sleep 1
    i=$(($i+1))
done
