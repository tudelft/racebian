#!/bin/bash -e

# somehow ssh takes over the locales from the client, which arent generated on the remote.
# let's just fix them here once and for all
echo "LC_ALL=${LOCALE_DEFAULT}" >> "${ROOTFS_DIR}/etc/default/locale"
