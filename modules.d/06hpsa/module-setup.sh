#!/bin/sh
#### Test the hpsa driver load with scan #####
#### Laurence Oberman loberman@redhat.com
### module-setup.sh - Required for every module
### Standard script invocations required
check() {
        return 0
}

### Install the hpsa.sh in the module directory
install() {
        inst_hook cmdline 20 "$moddir/parse-hpsa.sh"
        inst_simple "$moddir/hpsa.sh" /sbin/hpsa.sh
}
