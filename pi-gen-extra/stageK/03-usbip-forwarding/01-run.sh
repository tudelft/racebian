#!/bin/bash -e

## start usbipd at boot
# load relevant kernel modules at boot
install -m 644 files/modules.conf	"${ROOTFS_DIR}/etc/modules-load.d/usbip.conf"

# wrap usbipd in a systemd service: https://unix.stackexchange.com/questions/528769/usbip-startup-with-systemd
mkdir -p "${ROOTFS_DIR}/opt/usbip"
install -m 644 files/usbipd.service "${ROOTFS_DIR}/opt/usbip/"
ln -sf "/opt/usbip/usbipd.service" "${ROOTFS_DIR}/etc/systemd/system/usbipd.service"

# configure auto-binding of USB devices on port 1-1, also with systemd: https://unix.stackexchange.com/questions/406847/use-usbip-for-devices-that-are-being-removed-and-reconnected
mkdir -p "${ROOTFS_DIR}/var/spool/usbip/"
install -m 744 files/usbip-bind.sh "${ROOTFS_DIR}/opt/usbip/"
install -m 644 files/usbip-bind.service "${ROOTFS_DIR}/opt/usbip/"
ln -sf "/opt/usbip/usbip-bind.service" "${ROOTFS_DIR}/etc/systemd/system/usbip-bind.service"

# disable autobind, which causes issues with MSC mode on betaflight
sed -i '/^\s*exit 0\s*$/iecho 0 > /sys/bus/usb/drivers_autoprobe' "${ROOTFS_DIR}/etc/rc.local"

on_chroot << EOF
systemctl enable usbipd.service
systemctl enable usbip-bind.service
EOF
