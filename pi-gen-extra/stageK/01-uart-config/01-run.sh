#!/bin/bash -e

## disable initialization of the bluetooth module to free up UART
# https://www.abelectronics.co.uk/kb/article/1035/serial-port-setup-in-raspberry-pi-os
on_chroot << EOF
systemctl disable hciuart
EOF
