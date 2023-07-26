#!/bin/bash -e

if [ ! -d "${ROOTFS_DIR}" ]; then
	copy_previous
fi

## tblaha: re-format cmdline.txt for easier patching
# split up all arguments to new lines
sed -i 's/ \s*/\n/g' "${ROOTFS_DIR}/boot/cmdline.txt"
# remove empty lines
sed -i '/^$/d' "${ROOTFS_DIR}/boot/cmdline.txt"
# hope there are no commented lines..
