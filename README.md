# pi-kompaan
Pi-Zero Companion Computer for Betaflight

## Building

Tested on Ubuntu 22.04. First install these packages:
```
sudo apt install coreutils quilt parted qemu-user-static debootstrap zerofree \
zip dosfstools libarchive-tools libcap2-bin grep rsync xz-utils file git curl \
bc qemu-utils kpartx gpg pigz make
```

Then clone this repo *in an ext2 or ext4 filesystem, NOT NTFS*:
```
git clone --recurse-submodules git@github.com:tblaha/pi-kompaan.git
```

Build the image. The build script uses change-root. Do not interrupt it with CTRL-C or else you may have to reboot your system.
```
sudo make pi-image-kompaan
```

Flash the image. Take extreme care with this command, as it can break your system.
```
sudo umount /dev/mmcblk*
sudo dd bs=4M if=./build/pi-img/bin/<NAME OF THE IMAGE> of=/dev/<SD CARD DEVICE, NOT PARTITION, ENDS IN blkX> status=progress
```