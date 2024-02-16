#!/bin/bash -e

# get sources (latest non-buster kernel according to https://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/)
rm -rf "${STAGE_WORK_DIR}/linux"
git clone --depth=1 --branch=1.20230405 https://github.com/raspberrypi/linux "${STAGE_WORK_DIR}/linux"
cd ${STAGE_WORK_DIR}/linux

# get and apply RT patch-set. Not the same patchlevel as above, hope it still works
RT_VERSION=patches-6.1.38-rt13-rc1
wget https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/6.1/older/${RT_VERSION}.tar.gz
tar xfvz ${RT_VERSION}.tar.gz
cat ${RT_VERSION} | patch -p1

# configure the kernel
KERNEL=kernel8
make -j16 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig
./scripts/config --disable CONFIG_VIRTUALIZATION
./scripts/config --enable CONFIG_PREEMPT_RT
./scripts/config --disable CONFIG_RCU_EXPERT
./scripts/config --enable CONFIG_RCU_BOOST
./scripts/config --set-val CONFIG_RCU_BOOST_DELAY 500

# cross compile the kernel
make -j16 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs

# install kernel
env PATH=$PATH make -j16 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH="${ROOTFS_DIR}" modules_install

#cp mnt/fat32/"${KERNEL}".img mnt/fat32/"${KERNEL}"-backup.img
cp arch/arm64/boot/Image "${ROOTFS_DIR}/boot/${KERNEL}-rt.img"
cp arch/arm64/boot/dts/broadcom/*.dtb "${ROOTFS_DIR}/boot/"
cp arch/arm64/boot/dts/overlays/*.dtb* "${ROOTFS_DIR}/boot/overlays/"
cp arch/arm64/boot/dts/overlays/README "${ROOTFS_DIR}/boot/overlays/"

cd "${BASE_DIR}"
