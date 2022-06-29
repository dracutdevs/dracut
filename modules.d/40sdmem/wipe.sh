echo "Checking for mounted disks..."
dmsetup ls --target crypt
echo "WIPE RAM!"
/bin/sdmem -f
echo "WIPE DONE!"
