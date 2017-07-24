#!/bin/bash

#
# How to prepare:
# - ensure that the lvm thin pool is big enough
# - backup any (most likely /boot and /boot/efi) device with:
#  # mkdir /restoredev
#  # dev=<device>; umount $dev; dd if="$dev" of=/restoredev/$(systemd-escape -p "$dev"); mount $dev
# - backup the MBR
#  # dev=<device>; dd if="$dev" of=/restoredev/$(systemd-escape -p "$dev") bs=446 count=1
#
# # ls -l /dev/disk/by-path/virtio-pci-0000\:00\:07.0
# lrwxrwxrwx. 1 root root 9 Jul 24 04:27 /dev/disk/by-path/virtio-pci-0000:00:07.0 -> ../../vda
# # dev=/dev/disk/by-path/virtio-pci-0000:00:07.0
# # dd if="$dev" of=/restoredev/$(systemd-escape -p "$dev") bs=446 count=1
# # umount /boot/efi
# # dev=/dev/disk/by-partuuid/687177a8-86b3-4e37-a328-91d20db9563c
# # dd if="$dev" of=/restoredev/$(systemd-escape -p "$dev")
# # umount /boot
# # dev=/dev/disk/by-partuuid/4fdf99e9-4f28-4207-a26f-c76546824eaf
# # dd if="$dev" of=/restoredev/$(systemd-escape -p "$dev")
# # ls -al /restoredev/
# total 1253380
# drwx------.  2 root root        250 Jul 24 04:38 .
# dr-xr-xr-x. 18 root root        242 Jul 24 04:32 ..
# -rw-------. 1 root root  209715200 Jul 24 04:34 dev-disk-by\x2dpartuuid-4fdf99e9\x2d4f28\x2d4207\x2da26f\x2dc76546824eaf
# -rw-------. 1 root root 1073741824 Jul 24 04:34 dev-disk-by\x2dpartuuid-687177a8\x2d86b3\x2d4e37\x2da328\x2d91d20db9563c
# -rw-------. 1 root root        446 Jul 24 04:38 dev-disk-by\x2dpath-virtio\x2dpci\x2d0000:00:07.0
#
# - make a thin snapshot
# # lvm lvcreate -pr -s rhel/root --name reset
#
# - mark the snapshot with a tag
# # lvm lvchange --addtag reset rhel/reset
#
# - remove /restoredev
# # rm -fr /restoredev
#
# If a boot entry with rd.lvm.mergetags=<tag> is selected and there lv's with <tag>
# dracut will
# - make a copy of the snapshot
# - merge it back to the original
# - rename the copy back to the name of the snapshot
# - if /restordev appears in the root, then it will restore the images *.devimage
#   found in that directory. This can be used to restore /boot and /boot/efi.
#   Additionally any *.mbrimage files will be restored. This can be used 
#   found in that directory. This can be used to restore /boot and /boot/efi
#

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

do_merge() {
    sed -i -e 's/\(^[[:space:]]*\)locking_type[[:space:]]*=[[:space:]]*[[:digit:]]/\1locking_type = 1/' \
        /etc/lvm/lvm.conf

    systemctl --no-block stop sysroot.mount
    swapoff -a
    umount -R /sysroot

    for tag in $(getargs rd.lvm.mergetags); do
        lvm vgs --noheadings -o vg_name | \
            while read -r vg || [[ -n $vg ]]; do
                unset LVS
                declare -a LVS
                lvs=$(lvm lvs --noheadings -o lv_name "$vg")
                for lv in $lvs; do
                    lvm lvchange -an "$vg/$lv"

                    tags=$(trim "$(lvm lvs --noheadings -o lv_tags "$vg/$lv")")
                    strstr ",${tags}," ",${tag}," || continue

                    if ! lvm lvs --noheadings -o lv_name "${vg}/${lv}_dracutsnap" &>/dev/null; then
                        info "Creating backup ${lv}_dracutsnap of ${vg}/${lv}"
                        lvm lvcreate -pr -s "${vg}/${lv}" --name "${lv}_dracutsnap"
                    fi
                    lvm lvchange --addtag "$tag" "${vg}/${lv}_dracutsnap"

                    info "Merging back ${vg}/${lv} to the original LV"
                    lvm lvconvert --merge "${vg}/${lv}"

                    LVS+=($lv)
                done

                systemctl --no-block stop sysroot.mount
                udevadm settle

                for ((i=0; i < 100; i++)); do
                    lvm vgchange -an "$vg" && break
                    sleep 0.5
                done

                udevadm settle
                lvm vgchange -ay "$vg"
                udevadm settle
                for lv in "${LVS[@]}"; do
                    info "Renaming ${lv}_dracutsnap backup to ${vg}/${lv}"
                    lvm lvrename "$vg" "${lv}_dracutsnap" "${lv}"
                done
                udevadm settle
            done
    done

    systemctl --no-block reset-failed systemd-fsck-root
    systemctl --no-block start systemd-fsck-root
    systemctl --no-block reset-failed sysroot.mount
    systemctl --no-block start sysroot.mount

    for ((i=0; i < 100; i++)); do
        [[ -d /sysroot/dev ]] && break
        sleep 0.5
        systemctl --no-block start sysroot.mount
    done

    if [[ -d /sysroot/restoredev ]]; then
        (
            if cd /sysroot/restoredev; then
                # restore devices and partitions
                for i in *; do
                    target=$(systemd-escape -pu "$i")
                    if ! [[ -b $target ]]; then
                        warn "Not restoring $target, as the device does not exist"
                        continue
                    fi

                    # Just in case
                    umount "$target" &> /dev/null

                    info "Restoring $target"
                    dd if="$i" of="$target" |& vinfo
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

