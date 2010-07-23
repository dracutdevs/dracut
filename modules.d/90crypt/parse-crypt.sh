#!/bin/sh
if getarg rd_NO_LUKS; then
    info "rd_NO_LUKS: removing cryptoluks activation"
    rm -f /etc/udev/rules.d/70-luks.rules
else
    {
        echo 'SUBSYSTEM!="block", GOTO="luks_end"'
        echo 'ACTION!="add|change", GOTO="luks_end"'
    } > /etc/udev/rules.d/70-luks.rules

    LUKS=$(getargs rd_LUKS_UUID)
    unset settled
    [ -n "$(getargs rd_LUKS_KEYPATH)" ] && \
            [ -z "$(getargs rd_LUKS_KEYDEV_UUID)" ] && \
            settled='--settled'

    if [ -n "$LUKS" ]; then
        for luksid in $LUKS; do 
            {
                printf 'ENV{ID_FS_TYPE}=="crypto_LUKS", '
                printf 'ENV{ID_FS_UUID}=="*%s*", ' $luksid
                printf 'RUN+="/sbin/initqueue --unique --onetime %s ' "$settled"
                printf '--name cryptroot-ask-%%k /sbin/cryptroot-ask '
                printf '$env{DEVNAME} luks-$env{ID_FS_UUID}"\n'
            } >> /etc/udev/rules.d/70-luks.rules

            printf '[ -e /dev/disk/by-uuid/*%s* ] || exit 1\n' $luksid \
                    >> /initqueue-finished/crypt.sh
            {
                printf '[ -e /dev/disk/by-uuid/*%s* ] || ' $luksid
                printf 'warn "crypto LUKS UUID "%s" not found"\n' $luksid
            } >> /emergency/00-crypt.sh
        done
    else
        echo 'ENV{ID_FS_TYPE}=="crypto_LUKS", RUN+="/sbin/initqueue' $settled \
                '--unique --onetime --name cryptroot-ask-%k' \
                '/sbin/cryptroot-ask $env{DEVNAME} luks-$env{ID_FS_UUID}"' \
                >> /etc/udev/rules.d/70-luks.rules
    fi

    echo 'LABEL="luks_end"' >> /etc/udev/rules.d/70-luks.rules
fi
