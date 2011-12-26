#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# fixme: assume user is root

check() {
    # If our prerequisites are not met, fail.
    type -P ssh >/dev/null || return 1
    type -P scp >/dev/null || return 1
    if [[ $sshkey ]]; then
        [ ! -f $sshkey ] && {
            derror "sshkey is not found!"
            return 1
        }
        [[ ! $cttyhack = yes ]] && {
            dinfo "--ctty is not used, you should make sure the machine is knowhost and copy the sshkey to remote machine!"
        }
    else
        [[ ! $cttyhack = yes ]] && {
            derror "ssh interactive mode need option --ctty!"
            return 1
        }
    fi

    return 0
}

depends() {
    # We depend on network modules being loaded
    echo network
}

inst_sshenv()
{
    if [ -d /root/.ssh ]; then
        inst_dir /root/.ssh
        chmod 700 ${initdir}/root/.ssh
    fi

    # Copy over ssh key and knowhosts if needed
    [[ $sshkey ]] && {
        inst $sshkey
        [[ -f /root/.ssh/known_hosts ]] && inst /root/.ssh/known_hosts
        [[ -f /etc/ssh/ssh_known_hosts ]] && inst /etc/ssh/ssh_known_hosts
    }

    # Copy over root and system-wide ssh configs.
    [[ -f /root/.ssh/config ]] && inst /root/.ssh/config
    [[ -f /etc/ssh/ssh_config ]] && inst /etc/ssh/ssh_config

    return 0
}

install() {
    inst ssh
    inst scp
    inst_sshenv
}

