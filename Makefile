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
	rm -rf build

clean-imgs : 
	rm -rf imgs


## ---- Networking functions ---- ##

# if IFACE is not specified, try to guess based on kernel routing tab with 
# the idea that any interace is fine that has a route with:
# A: default Destination (0.0.0.0)
# B: NOT gateway 10.0.0.1 (the pi)
IFACE ?= $(shell route -n | grep "^0.0.0.0" | grep -v "10.0.0.1" | head -1 | awk '{print $$8}')

pi-routing-up : 
	@echo "Guessing that interface ${IFACE} has internet access."
# enable routing
	@sysctl -w net.ipv4.ip_forward=1
# docker changes the default filter FORWARD policy from ACCEPT to DROP.
# fix that with an explicit rule that allows outbound from the pi by default,
# but inbound only for related or established connections that originated from
# the pi (see Unix conntrack)
	-@iptables -t filter -D FORWARD -s 10.0.0.1 -o "${IFACE}" -j ACCEPT
	-@iptables -t filter -D FORWARD -d 10.0.0.1 -i "${IFACE}" -m state --state RELATED,ESTABLISHED -j ACCEPT
	@iptables -t filter -A FORWARD -s 10.0.0.1 -i "${IFACE}" -j ACCEPT
	@iptables -t filter -A FORWARD -d 10.0.0.1 -i "${IFACE}" -m state --state RELATED,ESTABLISHED -j ACCEPT
# create a new chain, ignoring errors if it already exists ("-")
	-@iptables -t nat -N fw-pi
# flush all of its rules in case it exists already
	@iptables -t nat -F fw-pi
# fwd all source 10.0.0.1 traffic to the new chain (delete then add to ensure only one)
	-@iptables -t nat -D POSTROUTING -s 10.0.0.1 -j fw-pi
	@iptables -t nat -A POSTROUTING -s 10.0.0.1 -j fw-pi
# allow outbound traffic on the IFACE that has connection to the internet gateway
	@iptables -t nat -A fw-pi -o "${IFACE}" -s 10.0.0.1 -j MASQUERADE
	@echo "Finished attempting iptables setup"

pi-routing-down : 
# do not forward POSTROUTING to fw-pi chain (ignore errors if rule already deleted)
	-@iptables -t nat -D POSTROUTING -s 10.0.0.1 -j fw-pi
# flush fw-pi table
	-@iptables -t nat -F fw-pi
# delete fw-pi tables
	-@iptables -t nat -X fw-pi
# delete accept rule in filter table
	-@iptables -t filter -D FORWARD -s 10.0.0.1 -o "${IFACE}" -j ACCEPT
	-@iptables -t filter -D FORWARD -d 10.0.0.1 -i "${IFACE}" -m state --state RELATED,ESTABLISHED -j ACCEPT
# disable routing
	@sysctl -w net.ipv4.ip_forward=0

pi-connect : pi-routing-up
# TODO: should this be a prerequisite?
	ssh -X -C -c aes128-ctr pi@10.0.0.1

pi-attach-usb : 
	modprobe vhci-hcd
	cp ./usbip-client/usbip-attach.service /etc/systemd/system/
	sed -i 's/REPLACE_ME/$(subst /,\/,$(shell pwd))\/usbip-client\/usbip-attach.sh/g' /etc/systemd/system/usbip-attach.service
	for port in 0 1 2 3 4 5 6 7 8 9 ; do \
		usbip detach -p $$port; \
	done
	systemctl daemon-reload
	systemctl stop usbip-attach.service
	systemctl start usbip-attach.service

