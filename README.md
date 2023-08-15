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
    - ~~If you can connect, but the `pi` still doesnt have internet, try to reconnect to the Wifi, or run `sudo route add default gw 10.0.0.<your_ip> wlan0`~~ (should be fixed in release 0.2.0)

## Deploy cmake applications on the Pi

Building directly on the Pi is inconvenient, because either the sources have to be modified Pi, or transferred via some mechanism. In any case building takes much longer because the Pi is much slower than any laptop and it is stateful (eg. there could be untracked changes to the sources on the Pi that may be forgotten about).

Solution: cross-compile on a laptop and only deploy the binaries. This makes the Pi completely stateless and the entire process much much smoother. See [cross-compiler](cross-compiler/README.md).


## Debugging / Flashing an SWD-capable microcontroller via the RPI

Wiring: 
```
SWCLK -- Broadcom GPIO25
SWDIO -- Broadcom GPIO24
RESET -- not used
GND   -- any
VCC   -- any 3V3 (for STM32 at least, I think)
```

### Setting the target chip
Only needs to be done one-time unless chip changes. 

Get list of available targets:
```shell
ssh pi@10.0.0.1 ls -lah /usr/share/openocd/scripts/target/stm32*.cfg
```

Point the config file to a specific chip:
```shell
ssh pi@10.0.0.1 sudo ln -sf /usr/share/openocd/scripts/target/stm32h7x.cfg /opt/openocd/chip.cfg
```

### Start debugging
Connect wires, then run:

```shell
ssh pi@10.0.0.1 sudo systemctl start openocd.service
```

Now, on your local machine, you can connect a local instance of `gdb-multilib`:
```shell
gdb-multilib
(gdb) target extended-remote 10.0.0.1:3333
(gdb) monitor reset
```

You will need these prerequisites:
```shell
apt install binutils-multilib gdb-multilib
```

#### integration in VSCode

Install the `Cortex-Debug` extension.

Use this `.vscode/launch.json` configuration (change executable of course, and compile with debug symbols on and optimisations off):
```json
{
    // Use IntelliSense to learn about possible Node.js debug attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "cwd": "${workspaceRoot}",
            "executable": "obj/main/betaflight_STM32H743.elf",
            "name": "Cortex OpenOCD",
            "request": "launch",
            "type": "cortex-debug",
            "servertype": "external",
            "gdbTarget": "10.0.0.1:3333",
            "runToEntryPoint": "main",
            "showDevDebugOutput": "none",
            "objdumpPath": "/usr/bin/objdump"
        }
    ]
}
```

Add this line to settings `.vscode/launch.json` configuration:
```json
    "cortex-debug.gdbPath.linux": "/usr/bin/gdb-multiarch"
```

### Flashing

1. Get an `.elf` binary onto the pi, using e.g. `sftp` or `rsync`
2. Make sure the debugger is stopped `ssh pi@10.0.0.1 sudo systemctl stop openocd.service`
3. Flash `ssh pi@10.0.0.1 'openocd -f /opt/openocd/openocd.cfg -c "program betaflight_STM32H743.elf verify reset exit"'`


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
