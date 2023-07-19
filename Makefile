
THIS_FILE := $(lastword $(MAKEFILE_LIST))

PIGEN_DIR = "ext/pi-gen"
EXTRA_DIR = "pi-gen-extra"

# Note: individual stages have not been configured with pre-requisites. Run them in the correct order manually!
.DEFAULT_GOAL := pi-image-kompaan
pi-stage1 : 
	rm -f ${PIGEN_DIR}/stage0/SKIP
	rm -f ${PIGEN_DIR}/stage1/SKIP
	cd ${PIGEN_DIR} && STAGE_LIST="stage0 stage1" ./build.sh -c ../../config

pi-stage2 : 
	touch ${PIGEN_DIR}/stage0/SKIP
	touch ${PIGEN_DIR}/stage1/SKIP
	rm -f ${EXTRA_DIR}/stage2/SKIP
	rm -f ${EXTRA_DIR}/stage2/SKIP_IMAGES
	cd ${PIGEN_DIR} && STAGE_LIST="stage0 stage1 ../../${EXTRA_DIR}/stage2" ./build.sh -c ../../config

pi-stage2-image :
	touch ${PIGEN_DIR}/stage0/SKIP
	touch ${PIGEN_DIR}/stage1/SKIP
	touch ${EXTRA_DIR}/stage2/SKIP
	rm -f ${EXTRA_DIR}/stage2/SKIP_IMAGES
	cd ${PIGEN_DIR} && STAGE_LIST="stage0 stage1 ../../${EXTRA_DIR}/stage2" ./build.sh -c ../../config

pi-stageK :
	touch ${PIGEN_DIR}/stage0/SKIP
	touch ${PIGEN_DIR}/stage1/SKIP
	touch ${EXTRA_DIR}/stage2/SKIP
	touch ${EXTRA_DIR}/stage2/SKIP_IMAGES
	rm -f ${EXTRA_DIR}/stageK/SKIP
	rm -f ${EXTRA_DIR}/stageK/SKIP_IMAGES
	cd ${PIGEN_DIR} && STAGE_LIST="stage0 stage1 ../../${EXTRA_DIR}/stage2 ../../${EXTRA_DIR}/stageK" ./build.sh -c ../../config

pi-image-lite : 
	$(MAKE) -f $(THIS_FILE) pi-stage1
	$(MAKE) -f $(THIS_FILE) pi-stage2

pi-image-kompaan : pi-image-lite
	$(MAKE) -f $(THIS_FILE) pi-stageK

pi-flash : 
	@echo sudo umount "/dev/mmcblk?*"
	@echo sudo dd bs=4M if=./build/pi-img/bin/your_image of=/dev/mmcblk? status=progress

pi-routing-up : 
	@sysctl -w net.ipv4.ip_forward=1
# add postrouting rule, unless already present
	@iptables -t nat -C POSTROUTING -o enxac91a193ecd6 -s 10.0.0.1 -j MASQUERADE || iptables -t nat -A POSTROUTING -o enxac91a193ecd6 -s 10.0.0.1 -j MASQUERADE

pi-routing-down : 
# || true to not treat missing rule as an error
	@iptables -t nat -D POSTROUTING -o enxac91a193ecd6 -s 10.0.0.1 -j MASQUERADE || true
	@sysctl -w net.ipv4.ip_forward=0

pi-connect : pi-routing-up
# TODO: should this be a prerequisite?
	ssh -X pi@10.0.0.1

clean : pi-routing-down
	rm -rf build

