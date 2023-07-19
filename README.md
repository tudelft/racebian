# pi-kompaan
Pi-Zero Companion Computer for Betaflight

## Connecting

Tested for Ubuntu 22.04 host computer. First install these packages:
```
sudo apt install make iptables
```

1. Flash a `Racebian` image.
2. Power the PI and connect to the WIFI network it hosts
    - SSID is `kompaan` by default, password `betaflight`.
    - Can be configured in `config` if you build the image yourself, or in `/etc/hostapd/hostapd.conf` if you mount the flashed SD card.
3. Run `sudo make pi-connect` and enter password (`pi` by default).
    - This also sets up appropriate `iptables` rules on the host so that the pi can access the outside world through another interface on the host computer.


## Optional: Building the image

Tested on Ubuntu 22.04. First install these packages:
```
sudo apt install coreutils quilt parted qemu-user-static debootstrap zerofree \
zip dosfstools libarchive-tools libcap2-bin grep rsync xz-utils file git curl \
bc qemu-utils kpartx gpg pigz make
```

Also, to cross-compile the RT kernel:
```
sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev crossbuild-essential-arm64
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