#!/bin/bash -e

## configure access point according to config
install -m 644 files/dhcpcd.conf	"${ROOTFS_DIR}/etc/dhcpcd.conf"

install -m 644 files/dnsmasq.conf	"${ROOTFS_DIR}/etc/dnsmasq.conf"

install -m 644 files/hostapd.conf   	"${ROOTFS_DIR}/etc/hostapd/hostapd.conf"
if [ -z ${WIFI_AP_SSID+x} ] && [ -z ${WIFI_AP_PASSPHRASE+x} ]; then
	echo "Please set WIFI_AP_SSID and/or WIFI_AP_PASSPHRASE in config" 1>&2
	exit 1
else
    sed -i "s/WIFI_AP_SSID/${WIFI_AP_SSID}/g"  "${ROOTFS_DIR}/etc/hostapd/hostapd.conf"
    sed -i "s/WIFI_AP_PASSPHRASE/${WIFI_AP_PASSPHRASE}/g"  "${ROOTFS_DIR}/etc/hostapd/hostapd.conf"
fi

install -m 644 files/hostapd   	"${ROOTFS_DIR}/etc/default/hostapd"

on_chroot << EOF
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq
EOF


## enable ipv4 forwarding on clientConnect
if [ "${ROUTE_THROUGH_CLIENTS}" == "1" ]; then
    install -m 755 files/rc.local   	"${ROOTFS_DIR}/etc/rc.local"
    install -m 755 files/onHostapdChange.sh "${ROOTFS_DIR}/etc/hostapd/onHostapdChange.sh"
    # modify the service file with a post-hook to enable the onHostapdChange script
    install -m 755 files/hostapd.service "${ROOTFS_DIR}/lib/systemd/system/hostapd.service"
fi

## disable ipv6 to reduce interrupt overhead
echo "ipv6.disable=1" >> "${ROOTFS_DIR}/boot/cmdline.txt"
