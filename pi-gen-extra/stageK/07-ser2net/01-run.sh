#!/bin/bash -e

# install the config
install -m 644 files/ser2net.yaml       "${ROOTFS_DIR}/etc/ser2net.yaml"

# fix the broken unit file
install -m 644 files/ser2net.service    "${ROOTFS_DIR}/lib/systemd/system/ser2net.service"

# DISABLED: superseded by the websocketd bridge (10-ws-bridge), which uses the same port 5761.
# The package's postinst enables the unit, so disable it explicitly. Package and config stay
# installed; to switch back on the Pi:
#   sudo systemctl disable --now websocketd && sudo systemctl enable --now ser2net
on_chroot << EOF
systemctl disable ser2net.service
EOF
