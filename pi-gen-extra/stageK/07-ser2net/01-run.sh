#!/bin/bash -e

# install the config
install -m 644 files/ser2net.yaml       "${ROOTFS_DIR}/etc/ser2net.yaml"

# fix the broken unit file
install -m 644 files/ser2net.service    "${ROOTFS_DIR}/lib/systemd/system/ser2net.service"

# enable unit
#on_chroot << EOF
#systemctl daemon-reload
#systemctl enable ser2net.service
#EOF
