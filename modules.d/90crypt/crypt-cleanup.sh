# close everything which is not busy
for i in /dev/mapper/luks-*; do
    cryptsetup luksClose $i &>/dev/null
done
