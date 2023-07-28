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

on_chroot << EOF
systemctl enable usbipd.service
systemctl enable usbip-bind.service
EOF

## eliminate system freezes on high freq USB comms under the RT patchset
# https://forums.raspberrypi.com/viewtopic.php?t=159170
# echo "dwc_otg.fiq_fsm_enable=0 dwc_otg.fiq_enable=0 dwc_otg.nak_holdoff=0" >> "${ROOTFS_DIR}/boot/cmdline.txt"
# should already be fixed in stage2 now
