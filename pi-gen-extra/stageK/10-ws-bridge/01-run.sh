#!/bin/bash -e

# WebSocket-to-serial bridge (websocketd + socat) for the Indiflight web configurator.
# Listens with TLS on port 5761 and forwards to /dev/indiflight (replaces ser2net, see 07-ser2net).

BRIDGE_DIR="${ROOTFS_DIR}/opt/indiflight-bridge"
install -d -m 755 "${BRIDGE_DIR}" "${BRIDGE_DIR}/www"
install -m 644 files/index.html        "${BRIDGE_DIR}/www/index.html"
install -m 755 files/ws-bridge-cert.sh "${BRIDGE_DIR}/ws-bridge-cert.sh"

install -m 644 files/ws-bridge-cert.service "${ROOTFS_DIR}/etc/systemd/system/ws-bridge-cert.service"
install -m 644 files/websocketd.service     "${ROOTFS_DIR}/etc/systemd/system/websocketd.service"

# udev rule providing the /dev/indiflight symlink
install -m 644 files/99-indiflight.rules    "${ROOTFS_DIR}/etc/udev/rules.d/99-indiflight.rules"

# certificate is generated on first boot, so images don't share a private key
on_chroot << CHEOF
systemctl enable ws-bridge-cert.service
systemctl enable websocketd.service
CHEOF
