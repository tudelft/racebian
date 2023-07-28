#!/bin/bash -e

## eliminate system freezes on high freq USB comms under the RT patchset
# https://forums.raspberrypi.com/viewtopic.php?t=159170
echo "dwc_otg.fiq_fsm_enable=0 dwc_otg.fiq_enable=0 dwc_otg.nak_holdoff=0" >> "${ROOTFS_DIR}/boot/cmdline.txt"
sed -i -z 's/\n/ /g' "${ROOTFS_DIR}/boot/cmdline.txt"
