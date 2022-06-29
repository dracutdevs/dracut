### Make sure sdmem is part of the initramfs
sudo apt-get install secure-delete 

sudo dracut --include /usr/bin/sdmem /etc/sdmem --force
