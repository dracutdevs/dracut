#!/bin/sh
if getarg rd_NO_LUKS; then
    info "rd_NO_LUKS: removing cryptoluks activation"
    rm -f /etc/udev/rules.d/70-luks.rules
else
    {
	echo 'SUBSYSTEM!="block", GOTO="luks_end"'
	echo 'ACTION!="add|change", GOTO="luks_end"'
    } > /etc/udev/rules.d/70-luks.rules
    LUKS=$(getargs rd_LUKS_UUID=)
    if [ -n "$LUKS" ]; then
	for luksid in $LUKS; do 
	printf 'ENV{ID_FS_TYPE}=="crypto_LUKS", ENV{ID_FS_UUID}=="*%s*", RUN+="/sbin/initqueue --unique --onetime --name cryptroot-ask-%%k /sbin/cryptroot-ask $env{DEVNAME} luks-$env{ID_FS_UUID}"\n' $luksid \
	    >> /etc/udev/rules.d/70-luks.rules	
	done
    else
	echo 'ENV{ID_FS_TYPE}=="crypto_LUKS", RUN+="/sbin/initqueue --unique --onetime --name cryptroot-ask-%k /sbin/cryptroot-ask $env{DEVNAME} luks-$env{ID_FS_UUID}"' \
	    >> /etc/udev/rules.d/70-luks.rules	
    fi
    echo 'LABEL="luks_end"' >> /etc/udev/rules.d/70-luks.rules

fi

