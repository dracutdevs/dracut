#!/bin/bash
inst cryptsetup
inst_rules "$dsrc/rules.d/63-luks.rules"
inst_hook mount 10 "$dsrc/hooks/cryptroot.sh"