#!/bin/bash -e

install -m 644 files/dhcpcd.conf	"${ROOTFS_DIR}/etc/dhcpcd.conf"

install -m 644 files/dnsmasq.conf	"${ROOTFS_DIR}/etc/dnsmasq.conf"

install -m 644 files/hostapd.conf   	"${ROOTFS_DIR}/etc/hostapd/hostapd.conf"

install -m 644 files/hostapd   	"${ROOTFS_DIR}/etc/default/hostapd"

on_chroot << EOF
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq
EOF
