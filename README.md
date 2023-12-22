# racebian

Pi-Zero Companion Computer for Betaflight

## Connecting to the Pi

Tested for Ubuntu 22.04 host computer. First install these packages:
```bash
sudo apt install make iptables
```

Then clone this repo, and install the custom commands and services:
```bash
sudo make install-pi-tools
```

1. Flash a `Racebian` image from `https://github.com/tblaha/racebian/releases` or build yourself (see below).
2. Power the PI and connect to the WIFI network it hosts
    - SSID is `racebian` by default, password `betaflight`.
    - Can be configured in `/etc/hostapd/hostapd.conf` if you mount the flashed SD card (or in `./config` of this repo, if you build the image yourself)
    - you can now connect via `ssh pi@10.0.0.1` with password `pi`
3. ~~To expose the Pi zero's USB port to your local laptop, just start the service~~ Version 0.4.0: we are now using `ser2net` to tunnel the serial USB via TCP which doesn't need client configuration and is more stable
    - `sudo systemctl start pi-usb-attach`
    - if it ever acts up, just restart with `sudo systemctl restart pi-usb-attach`
4. To let the Pi access all other networks of the laptop client:
    - `sudo pi-routing-up 10.0.0.1`
    - (to restrict to only a certain interface, do `sudo pi-routing-up --iface=<INTERFACE> 10.0.0.1`)
5. ~~if the Pi still doesn't have internet/optitrack connection try this:~~ (should be fixed in 0.2.0!)
    - on the Pi, run `sudo route add default gw 10.0.0.<your_laptop_ip> wlan0`
    - you can find the laptop ip by running `ip a | grep 10.0.0.` on the laptop.

## Deploy cmake applications on the Pi

Building directly on the Pi is inconvenient, because either the sources have to be modified Pi, or transferred via some mechanism. In any case building takes much longer because the Pi is much slower than any laptop and it is stateful (eg. there could be untracked changes to the sources on the Pi that may be forgotten about).

Solution: cross-compile on a laptop and only deploy the binaries. This makes the Pi completely stateless and the entire process much much smoother. See [cross-compiler](cross-compiler/README.md).


## Debugging / Flashing an SWD-capable microcontroller via the Pi

This is relatively easy to setup and super useful. See [README_SWD.md](README_SWD.md).


## Downloading files from USB mass storage device

When connecting a USB mass storage device (such as a flight controller in MSC mode), `ser2net` cannot forward this, because a USB MSC device is not serial (but rather appears as a disk such as `/dev/sda`). A neat way to download data from this is to mount the storage device, and use `rsync` to download via `ssh`. An example script that can be used as a VS Code task is provided in [usb-download](usb-download).



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
git clone --recurse-submodules git@github.com:tblaha/racebian.git
```

### Building

Build the image *with a stable Ethernet connection* (it didnt find some packages when I tried via wifi and quit). The build script uses change-root. Do not interrupt it with CTRL-C or else you may have to reboot your system.
```bash
# sudo make clean # optional
LC_ALL=en_US.UTF-8 sudo make pi-image-racebian
```

### Flashing

Flash the image. Take extreme care with this command, as it can break your system.
```bash
sudo umount /dev/mmcblk*
sudo dd bs=4M if=./build/pi-img/bin/<NAME OF THE IMAGE> of=/dev/<SD CARD DEVICE, NOT PARTITION, ENDS IN blkX> status=progress
```

## TODO:

- [x] remove the cross compiled BF-configurator, if usbip works.
- ~~[ ] write ansible playbooks for uploading betaflight `hex` files~~ no need thanks to `usbip`
- [ ] dockerize this to eliminate build-system dependencies
- [x] add betaflight_race receiver and optitrack code
- ~~[ ] put `make pi-attach-usb` commands in pre-start/post-exit hooks of the systemd service~~
- [x] reformulate more `make` commands as actual commands, maybe with a `pi-util` shell or python script
