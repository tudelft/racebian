#!/bin/bash -e

# get BF configurator sources
BF_DIR="${STAGE_WORK_DIR}/betaflight-configurator"
rm -rf "${BF_DIR}"
git clone --branch=master --depth=1 https://github.com/betaflight/betaflight-configurator "${BF_DIR}"

# get NWjs arm64 binaries manually, because there's an upstream bug in the gulpfile
mkdir -p "${BF_DIR}/cache/0.77.0-sdk"
cd "${BF_DIR}/cache/0.77.0-sdk"
wget https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nw60-arm64_2022-01-08/nw60-arm64_2022-01-08.tar.gz
tar xfz nw60-arm64_2022-01-08.tar.gz 
mv usr/docker/dist/nwjs-chromium-ffmpeg-branding/nwjs-v0.60.1-linux-arm64.tar.gz .
tar xfz nwjs-v0.60.1-linux-arm64.tar.gz
mv nwjs-v0.60.1-linux-arm64 linux32 # dont ask why

# apply cache-beun to the beun-buildsystem that's very beun
touch "${BF_DIR}/cache/_ARMv8_IS_CACHED"

# cross-compile modules, fingers crossed
cd "${BF_DIR}"
npm_config_target_arch=arm64 npm_config_target_platform=linux yarn install --arch=arm64 --verbose

# cross-compile application (in debug profile, for now)
npm_config_target_arch=arm64 npm_config_target_platform=linux yarn gulp debug --armv8

# install the binaries and create a symlink
cp -R "${BF_DIR}/debug/betaflight-configurator/armv8" "${ROOTFS_DIR}/opt/betaflight-configurator"
ln -nsf "/opt/betaflight-configurator/betaflight-configurator" "${ROOTFS_DIR}/usr/bin/betaflight-configurator"

cd "${BASE_DIR}"