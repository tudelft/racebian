# pi-kompaan

Pi-Zero Companion Computer for Betaflight

## Connecting to the Pi

Tested for Ubuntu 22.04 host computer. First install these packages:
```bash
sudo apt install make iptables
```

1. Flash a `Racebian` image from `https://github.com/tblaha/pi-kompaan/releases` or build yourself (see below).
2. Power the PI and connect to the WIFI network it hosts
    - SSID is `kompaan` by default, password `betaflight`.
    - Can be configured in `/etc/hostapd/hostapd.conf` if you mount the flashed SD card (or in `./config` of this repo, if you build the image yourself)
3. To expose the Pi zero's USB port to your local laptop: `sudo make pi-attach-usb`
4. To connect to the Pi, run `sudo make pi-connect` and enter password (`pi` by default).
    - This also sets up appropriate `iptables` rules on the host so that the pi can access the outside world through another interface on the host computer.
    - ~~If you can connect, but the `pi` still doesnt have internet, try to reconnect to the Wifi, or run `sudo route add default gw 10.0.0.<your_ip> wlan0`~~ (should be fixed in release 0.3.0)

## Deploy cmake applications on the Pi

Building directly on the Pi is inconvenient, because either the sources have to be modified Pi, or transferred via some mechanism. In any case building takes much longer because the Pi is much slower than any laptop and it is stateful (eg. there could be untracked changes to the sources on the Pi that may be forgotten about).

Solution: cross-compile on a laptop and only deploy the binaries. This makes the Pi completely stateless and the entire process much much smoother. See [cross-compiler](cross-compiler/README.md).


## Optional: Building the image

TODO --> dockerize this, so we don't have to deal with dependency hell

### Prerequesites

Tested on Ubuntu 22.04. First install these packages:
```bash
sudo apt install coreutils quilt parted qemu-user-static debootstrap zerofree \
    zip dosfstools libarchive-tools libcap2-bin grep rsync xz-utils file git curl \
    bc qemu-utils kpartx gpg pigz make git bc bison flex libssl-dev make libc6-dev \
    libncurses5-dev crossbuild-essential-arm64 \
    linux-tools-virtual linux-tools-$(uname -r) hwdata \
```

<!--
Also, to cross-compile the RT kernel:
```bash
sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev crossbuild-essential-arm64
```

To use BF configurator via usb forwarding later, install this:
```bash
sudo apt install linux-tools-virtual linux-tools-$(uname -r) hwdata
```
-->

Generate the default locale used in the pi images (which we'll keep):
```bash
sudo locale-gen en_US.UTF-8
```

Then clone this repo *in an ext2 or ext4 filesystem, NOT NTFS*:
```bash
git clone --recurse-submodules git@github.com:tblaha/pi-kompaan.git
```

### Building

Build the image *with a stable Ethernet connection* (it didnt find some packages when I tried via wifi and quit). The build script uses change-root. Do not interrupt it with CTRL-C or else you may have to reboot your system.
```bash
# sudo make clean # optional
LC_ALL=en_US.UTF-8 sudo make pi-image-kompaan
```

### Flashing

Flash the image. Take extreme care with this command, as it can break your system.
```bash
sudo umount /dev/mmcblk*
sudo dd bs=4M if=./build/pi-img/bin/<NAME OF THE IMAGE> of=/dev/<SD CARD DEVICE, NOT PARTITION, ENDS IN blkX> status=progress
```

## TODO:

- [x] remove the cross compiled BF-configurator, if usbip works.
- ~~[] write ansible playbooks for uploading betaflight `hex` files~~ no need thanks to `usbip`
- [] dockerize this to eliminate build-system dependencies
- [] add betaflight_race receiver and optitrack code
