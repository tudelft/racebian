#!/bin/bash -e

## configure access point and client according to config
install -m 600 files/Hotspot.nmconnection "${ROOTFS_DIR}/etc/NetworkManager/system-connections/Hotspot.nmconnection"
install -m 600 files/Client.nmconnection "${ROOTFS_DIR}/etc/NetworkManager/system-connections/Client.nmconnection"

# change access point settings
if [ -z ${WIFI_AP_SSID+x} ] && [ -z ${WIFI_AP_PASSPHRASE+x} ]; then
	echo "Please set WIFI_AP_SSID and/or WIFI_AP_PASSPHRASE in config" 1>&2
	exit 1
else
    sed -i "s/WIFI_AP_SSID/${WIFI_AP_SSID}/g"  "${ROOTFS_DIR}/etc/NetworkManager/system-connections/Hotspot.nmconnection"
    sed -i "s/WIFI_AP_PASSPHRASE/${WIFI_AP_PASSPHRASE}/g"  "${ROOTFS_DIR}/etc/NetworkManager/system-connections/Hotspot.nmconnection"
fi

# change wifi client settings
if [ -z ${WIFI_CLIENT_SSID+x} ] && [ -z ${WIFI_CLIENT_PASSPHRASE+x} ]; then
	echo "Please set WIFI_CLIENT_SSID and/or WIFI_CLIENT_PASSPHRASE in config" 1>&2
	exit 1
else
    sed -i "s/WIFI_CLIENT_SSID/${WIFI_CLIENT_SSID}/g"  "${ROOTFS_DIR}/etc/NetworkManager/system-connections/Client.nmconnection"
    sed -i "s/WIFI_CLIENT_PASSPHRASE/${WIFI_CLIENT_PASSPHRASE}/g"  "${ROOTFS_DIR}/etc/NetworkManager/system-connections/Client.nmconnection"
fi
