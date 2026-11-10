#!/bin/bash -e
# Generate a per-device self-signed TLS certificate for the websocket bridge.
# Runs at every boot (see ws-bridge-cert.service) but only generates when the existing
# cert/key are missing or unreadable, so every image gets its own key on first boot and
# a truncated pair (e.g. after a power cut) heals itself.
BRIDGE_DIR=/opt/indiflight-bridge
IP=10.0.0.1
CERT="${BRIDGE_DIR}/cert.pem"
KEY="${BRIDGE_DIR}/key.pem"

if openssl x509 -noout -in "${CERT}" 2>/dev/null && openssl pkey -noout -in "${KEY}" 2>/dev/null; then
    exit 0
fi
echo "No valid certificate/key in ${BRIDGE_DIR}, generating a new pair"

umask 077
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "${KEY}.tmp" -out "${CERT}.tmp" \
    -subj "/CN=${IP}" -addext "subjectAltName=IP:${IP}"
chmod 644 "${CERT}.tmp"
chmod 600 "${KEY}.tmp"

# Flush contents to the SD card *before* the rename. Otherwise ext4 can commit the rename
# while the data is still in the page cache, and a power loss leaves 0-byte files behind.
sync "${CERT}.tmp" "${KEY}.tmp"
mv "${CERT}.tmp" "${CERT}"
mv "${KEY}.tmp"  "${KEY}"
sync "${BRIDGE_DIR}"
