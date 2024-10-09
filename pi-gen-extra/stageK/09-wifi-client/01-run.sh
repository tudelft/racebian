#!/bin/bash -e

## configure access point according to config
install -m 600 files/preconfigured.nmconnection "${ROOTFS_DIR}/etc/NetworkManager/system-connections/preconfigured.nmconnection"
