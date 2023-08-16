#!/bin/bash -e

mkdir -p "${ROOTFS_DIR}/opt/openocd"

install -m 644 files/openocd.service "${ROOTFS_DIR}/opt/openocd/openocd.service"
ln -sf "/opt/openocd/openocd.service" "${ROOTFS_DIR}/etc/systemd/system/openocd.service"

install -m 644 files/openocd.cfg "${ROOTFS_DIR}/opt/openocd/"
install -m 644 files/openocd_debug.cfg "${ROOTFS_DIR}/opt/openocd/"
ln -sf /usr/share/openocd/scripts/target/stm32h7x.cfg "${ROOTFS_DIR}/opt/openocd/chip.cfg"

# wrap usbipd in a systemd service: https://unix.stackexchange.com/questions/528769/usbip-startup-with-systemd
#mkdir -p "${ROOTFS_DIR}/opt/usbip"
#install -m 644 files/usbipd.service "${ROOTFS_DIR}/opt/usbip/"
#ln -sf "/opt/usbip/usbipd.service" "${ROOTFS_DIR}/etc/systemd/system/usbipd.service"

#on_chroot << EOF
#systemctl enable usbipd.service
#systemctl enable usbip-bind.service
#EOF
