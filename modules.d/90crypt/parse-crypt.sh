#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type crypttab_contains >/dev/null 2>&1 || . /lib/dracut-crypt-lib.sh

if ! getargbool 1 rd.luks -d -n rd_NO_LUKS; then
    info "rd.luks=0: removing cryptoluks activation"
    rm -f -- /etc/udev/rules.d/70-luks.rules
else
    {
        echo 'SUBSYSTEM!="block", GOTO="luks_end"'
        echo 'ACTION!="add|change", GOTO="luks_end"'
    } > /etc/udev/rules.d/70-luks.rules.new

    LUKS=$(getargs rd.luks.uuid -d rd_LUKS_UUID)
    tout=$(getarg rd.luks.key.tout)

    if [ -n "$LUKS" ]; then
        for luksid in $LUKS; do

            luksid=${luksid##luks-}

            if [ -z "$DRACUT_SYSTEMD" ]; then
                {
                    printf -- 'ENV{ID_FS_TYPE}=="crypto_LUKS", '
                    printf -- 'ENV{ID_FS_UUID}=="*%s*", ' $luksid
                    printf -- 'RUN+="%s --settled --unique --onetime ' $(command -v initqueue)
                    printf -- '--name cryptroot-ask-%%k %s ' $(command -v cryptroot-ask)
                    printf -- '$env{DEVNAME} luks-$env{ID_FS_UUID} %s"\n' $tout
                } >> /etc/udev/rules.d/70-luks.rules.new
            else
                if ! crypttab_contains "$luksid"; then
                    {
                        printf -- 'ENV{ID_FS_TYPE}=="crypto_LUKS", '
                        printf -- 'ENV{ID_FS_UUID}=="*%s*", ' $luksid
                        printf -- 'RUN+="%s --settled --unique --onetime ' $(command -v initqueue)
                        printf -- '--name systemd-cryptsetup-%%k %s start ' $(command -v systemctl)
                        printf -- 'systemd-cryptsetup@luks$$(dev_unit_name -$env{ID_FS_UUID}).service"\n'
                    } >> /etc/udev/rules.d/70-luks.rules.new
                fi
            fi

            uuid=$luksid
            while [ "$uuid" != "${uuid#*-}" ]; do uuid=${uuid%%-*}${uuid#*-}; done
            printf -- '[ -e /dev/disk/by-id/dm-uuid-CRYPT-LUKS?-*%s*-* ] || exit 1\n' $uuid \
                >> $hookdir/initqueue/finished/90-crypt.sh

            {
                printf -- '[ -e /dev/disk/by-uuid/*%s* ] || ' $luksid
                printf -- 'warn "crypto LUKS UUID "%s" not found"\n' $luksid
            } >> $hookdir/emergency/90-crypt.sh
        done
    elif getargbool 0 rd.auto; then
        if [ -z "$DRACUT_SYSTEMD" ]; then
            {
                printf -- 'ENV{ID_FS_TYPE}=="crypto_LUKS", RUN+="%s ' $(command -v initqueue)
                printf -- '--unique --settled --onetime --name cryptroot-ask-%%k '
                printf -- '%s $env{DEVNAME} luks-$env{ID_FS_UUID} %s"\n' $(command -v cryptroot-ask) $tout
            } >> /etc/udev/rules.d/70-luks.rules.new
        else
            {
                printf -- 'ENV{ID_FS_TYPE}=="crypto_LUKS", RUN+="%s ' $(command -v initqueue)
                printf -- '--unique --settled --onetime --name crypt-run-generator-%%k '
                printf -- '%s $env{DEVNAME} luks-$env{ID_FS_UUID}"\n' $(command -v crypt-run-generator)
            } >> /etc/udev/rules.d/70-luks.rules.new
        fi
    fi

    echo 'LABEL="luks_end"' >> /etc/udev/rules.d/70-luks.rules.new
    mv /etc/udev/rules.d/70-luks.rules.new /etc/udev/rules.d/70-luks.rules
fi
