#!/bin/bash -e

# get sources (latest non-buster kernel according to https://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/)
rm -rf "${STAGE_WORK_DIR}/linux"
git clone --depth=1 --branch=stable_20250916 https://github.com/raspberrypi/linux "${STAGE_WORK_DIR}/linux"
cd ${STAGE_WORK_DIR}/linux

# get and apply RT patch. (see kernel Makefile for version) --> since 6.12, the RT patch is now merged into mainline, so we just need to enable it in the config
# KERNEL_VERSION=6.12.47
# RT_VERSION=patches-${KERNEL_VERSION}-rt31
# wget https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/6.6/older/${RT_VERSION}.tar.gz
# tar xfvz ${RT_VERSION}.tar.gz
# cat ${RT_VERSION} | patch -p1


# configure the kernel
# KERNEL=kernel8
# make -j16 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig # RPi4/RPi400/Zero2W/CM4...

KERNEL=kernel_2712
make -j16 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2712_defconfig # RPi5
./scripts/config --disable CONFIG_VIRTUALIZATION
./scripts/config --enable CONFIG_PREEMPT_RT
./scripts/config --disable CONFIG_RCU_EXPERT
./scripts/config --enable CONFIG_RCU_BOOST
./scripts/config --set-val CONFIG_RCU_BOOST_DELAY 500
 
# cross compile the kernel
make -j16 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs

KERNEL_VERSION=$(<include/config/kernel.release)
echo "KERNEL_VERSION ${KERNEL_VERSION}"
echo "ROOTFS_DIR ${ROOTFS_DIR}"
echo "BASE_DIR ${BASE_DIR}"
echo

# install kernel
rm -rf "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}" # if not properly cleaned?
env PATH=$PATH make -j16 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH="${ROOTFS_DIR}" modules_install

#cp mnt/fat32/"${KERNEL}".img mnt/fat32/"${KERNEL}"-backup.img
cp arch/arm64/boot/Image "${ROOTFS_DIR}/boot/firmware/${KERNEL}-rt.img"
cp arch/arm64/boot/dts/broadcom/*.dtb "${ROOTFS_DIR}/boot/firmware/"
cp arch/arm64/boot/dts/overlays/*.dtb* "${ROOTFS_DIR}/boot/firmware/overlays/"
cp arch/arm64/boot/dts/overlays/README "${ROOTFS_DIR}/boot/firmware/overlays/"

cd "${BASE_DIR}"

# copy kernel headers and build tools
rm -rf "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/source"
rm -rf "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/build"
mkdir "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/source"
cp -r ${STAGE_WORK_DIR}/linux/.config "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/source"
cp -r ${STAGE_WORK_DIR}/linux/Makefile "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/source"
cp -r ${STAGE_WORK_DIR}/linux/Module.symvers "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/source"
cp -r ${STAGE_WORK_DIR}/linux/arch "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/source"
cp -r ${STAGE_WORK_DIR}/linux/include "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/source"
cp -r ${STAGE_WORK_DIR}/linux/tools "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/source"

# need to grab build tools from old kernel because the scripts are still not crosscompiled because i dont even remotely have the patience to sort this properly, argdsagfas.dg.fhadfgaeaer
ln -sf "/lib/linux-kbuild-6.6/scripts" "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/source/scripts"
ln -sf "/lib/modules/${KERNEL_VERSION}/source" "${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/build"
