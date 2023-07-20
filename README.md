# pi-kompaan

Pi-Zero Companion Computer for Betaflight

## Connecting to the Pi

Tested for Ubuntu 22.04 host computer. First install these packages:
```bash
sudo apt install make iptables
```

1. Flash a `Racebian` image from `https://github.com/tblaha/pi-kompaan/releases` or build yourself.
2. Power the PI and connect to the WIFI network it hosts
    - SSID is `kompaan` by default, password `betaflight`.
    - Can be configured in `config` if you build the image yourself, or in `/etc/hostapd/hostapd.conf` if you mount the flashed SD card.
3. Run `sudo make pi-connect` and enter password (`pi` by default).
    - This also sets up appropriate `iptables` rules on the host so that the pi can access the outside world through another interface on the host computer.
    - If you can connect, but the `pi` still doesnt have internet, try to reconnect to the Wifi, or run `sudo route add default gw 10.0.0.<your_ip> wlan0`


## Optional: Building the image

TODO --> dockerize this, so we don't have to deal with dependency hell, especially for BF-configurator

Tested on Ubuntu 22.04. First install these packages:
```bash
sudo apt install coreutils quilt parted qemu-user-static debootstrap zerofree \
zip dosfstools libarchive-tools libcap2-bin grep rsync xz-utils file git curl \
bc qemu-utils kpartx gpg pigz make
```

Also, to cross-compile the RT kernel:
```bash
sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev crossbuild-essential-arm64
```

And, to cross-compile BF-configurator: TODO: improve this abomination
```bash
sudo apt install libatomic1 npm
sudo npm install -g gulp-cli yarn
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | sudo bash
sudo su -c "NVM_DIR=/root/.nvm source $NVM_DIR/nvm.sh && nvm install 16 && cp /root/.nvm/versions/node/v16.14.0/bin/node /usr/bin/node"
```

Then clone this repo *in an ext2 or ext4 filesystem, NOT NTFS*:
```bash
git clone --recurse-submodules git@github.com:tblaha/pi-kompaan.git
```

Build the image. The build script uses change-root. Do not interrupt it with CTRL-C or else you may have to reboot your system.
```bash
# sudo make clean # optional
sudo make pi-image-kompaan
```

Flash the image. Take extreme care with this command, as it can break your system.
```bash
sudo umount /dev/mmcblk*
sudo dd bs=4M if=./build/pi-img/bin/<NAME OF THE IMAGE> of=/dev/<SD CARD DEVICE, NOT PARTITION, ENDS IN blkX> status=progress
```