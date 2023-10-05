SHELL := /bin/bash
THIS_FILE := $(lastword $(MAKEFILE_LIST))

PIGEN_DIR = "ext/pi-gen"
EXTRA_DIR = "pi-gen-extra"

locale_check : 
ifneq ("$(LC_ALL)","en_US.UTF-8")
	$(error "LC_ALL should be set to en_US.UTF-8, see README.md")
endif

# Note: individual stages have not been configured with pre-requisites. Run them in the correct order manually!
.DEFAULT_GOAL := pi-image-kompaan
pi-stage1 : locale_check
	rm -f ${PIGEN_DIR}/stage0/SKIP
	rm -f ${PIGEN_DIR}/stage1/SKIP
	cd ${PIGEN_DIR} && STAGE_LIST="stage0 stage1" ./build.sh -c ../../config

pi-stage2 : locale_check
	touch ${PIGEN_DIR}/stage0/SKIP
	touch ${PIGEN_DIR}/stage1/SKIP
	rm -f ${EXTRA_DIR}/stage2/SKIP
	rm -f ${EXTRA_DIR}/stage2/SKIP_IMAGES
	cd ${PIGEN_DIR} && STAGE_LIST="stage0 stage1 ../../${EXTRA_DIR}/stage2" ./build.sh -c ../../config

pi-stage2-image : locale_check
	touch ${PIGEN_DIR}/stage0/SKIP
	touch ${PIGEN_DIR}/stage1/SKIP
	touch ${EXTRA_DIR}/stage2/SKIP
	rm -f ${EXTRA_DIR}/stage2/SKIP_IMAGES
	cd ${PIGEN_DIR} && STAGE_LIST="stage0 stage1 ../../${EXTRA_DIR}/stage2" ./build.sh -c ../../config

pi-stageK : locale_check
	touch ${PIGEN_DIR}/stage0/SKIP
	touch ${PIGEN_DIR}/stage1/SKIP
	touch ${EXTRA_DIR}/stage2/SKIP
	touch ${EXTRA_DIR}/stage2/SKIP_IMAGES
	rm -f ${EXTRA_DIR}/stageK/SKIP
	rm -f ${EXTRA_DIR}/stageK/SKIP_IMAGES
	cd ${PIGEN_DIR} && STAGE_LIST="stage0 stage1 ../../${EXTRA_DIR}/stage2 ../../${EXTRA_DIR}/stageK" ./build.sh -c ../../config

pi-image-lite :  locale_check
	$(MAKE) -f $(THIS_FILE) pi-stage1
	$(MAKE) -f $(THIS_FILE) pi-stage2

pi-image-kompaan : pi-image-lite locale_check
	$(MAKE) -f $(THIS_FILE) pi-stageK

pi-flash : 
	@echo sudo umount "/dev/mmcblk?*"
	@echo sudo dd bs=4M if=./imgs/your_image of=/dev/mmcblk? status=progress

clean : 
	@echo -n
ifneq (, $(shell mount | grep rootfs))
	@echo "something went wrong, please unmount rootfs manually."
endif
	rm -rf build

clean-imgs : 
	rm -rf imgs


## ---- Networking functions ---- ##
install-pi-tools : 
#	install -m 755 -o root ./usbip-client/usbip-attach.sh /usr/bin/pi-usb-attach
#	install -m 644 -o root ./usbip-client/usbip-attach.service /etc/systemd/system/pi-usb-attach.service
	install -m 755 -o root ./routing/routing-up.sh /usr/bin/pi-routing-up
	install -m 755 -o root ./routing/routing-down.sh /usr/bin/pi-routing-down
#	systemctl daemon-reload
