#!/bin/bash -e
# Generate a per-device self-signed TLS certificate for the websocket bridge.
# Runs once on first boot (see ws-bridge-cert.service), so every image gets its own key.
BRIDGE_DIR=/opt/indiflight-bridge
IP=10.0.0.1

umask 077
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "${BRIDGE_DIR}/key.pem.tmp" -out "${BRIDGE_DIR}/cert.pem.tmp" \
    -subj "/CN=${IP}" -addext "subjectAltName=IP:${IP}"
chmod 644 "${BRIDGE_DIR}/cert.pem.tmp"
chmod 600 "${BRIDGE_DIR}/key.pem.tmp"
mv "${BRIDGE_DIR}/cert.pem.tmp" "${BRIDGE_DIR}/cert.pem"
mv "${BRIDGE_DIR}/key.pem.tmp"  "${BRIDGE_DIR}/key.pem"
