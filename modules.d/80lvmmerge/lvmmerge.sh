#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

do_merge() {
    sed -i -e 's/\(^[[:space:]]*\)locking_type[[:space:]]*=[[:space:]]*[[:digit:]]/\1locking_type = 1/' \
        /etc/lvm/lvm.conf

    systemctl --no-block stop sysroot.mount
    swapoff -a
    umount -R /sysroot

    for tag in $(getargs rd.lvm.mergetags); do
        lvm vgs --noheadings -o vg_name \
            | while read -r vg || [ -n "$vg" ]; do
                LVS=
                for lv in $(lvm lvs --noheadings -o lv_name "$vg"); do
                    lvm lvchange -an "$vg/$lv"

                    tags=$(trim "$(lvm lvs --noheadings -o lv_tags "$vg/$lv")")
                    strstr ",${tags}," ",${tag}," || continue

                    if ! lvm lvs --noheadings -o lv_name "${vg}/${lv}_dracutsnap" > /dev/null 2>&1; then
                        info "Creating backup ${lv}_dracutsnap of ${vg}/${lv}"
                        lvm lvcreate -pr -s "${vg}/${lv}" --name "${lv}_dracutsnap"
                    fi
                    lvm lvchange --addtag "$tag" "${vg}/${lv}_dracutsnap"

                    info "Merging back ${vg}/${lv} to the original LV"
                    lvm lvconvert --merge "${vg}/${lv}"

                    LVS="$LVS $lv"
                done

                systemctl --no-block stop sysroot.mount
                udevadm settle

                i=0
                while [ $i -lt 100 ]; do
                    lvm vgchange -an "$vg" && break
                    sleep 0.5
                    i=$((i + 1))
                done

                udevadm settle
                lvm vgchange -ay "$vg"
                udevadm settle
                for lv in $LVS; do
                    info "Renaming ${lv}_dracutsnap backup to ${vg}/${lv}"
                    lvm lvrename "$vg" "${lv}_dracutsnap" "${lv}"
                done
                udevadm settle
            done
    done

    systemctl --no-block reset-failed systemd-fsck-root sysroot.mount
    systemctl --no-block start systemd-fsck-root
    systemctl --no-block start sysroot.mount

    i=0
    while [ $i -lt 100 ]; do
        [ -d /sysroot/dev ] && break
        sleep 0.5
        systemctl --no-block start sysroot.mount
        i=$((i + 1))
    done

    if [ -d /sysroot/restoredev ]; then
        (
            if cd /sysroot/restoredev; then
                # restore devices and partitions
                for i in *; do
                    target=$(systemd-escape -pu "$i")
                    if ! [ -b "$target" ]; then
                        warn "Not restoring $target, as the device does not exist"
                        continue
                    fi

                    # Just in case
                    umount "$target" > /dev/null 2>&1

                    info "Restoring $target"
                    dd if="$i" of="$target" 2>&1 | vinfo
                done
            fi
        )
        mount -o remount,rw /sysroot
        rm -fr /sysroot/restoredev
    fi
    info "Rebooting"
    reboot
}

if getarg rd.lvm.mergetags; then
    do_merge
fi
