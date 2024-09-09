#!/bin/bash -e

## undo kernel command line hack
sed -i -z 's/\n/ /g' "${ROOTFS_DIR}/boot/firmware/cmdline.txt"
