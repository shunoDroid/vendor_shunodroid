#!/bin/bash

# Set target device from commandline args
if [ $# -eq 1 ]
then
    export TARGET_DEVICE=$1
else
    echo "usage: $0 <device>"
    echo "ex: $0 satsuki"
    exit 1
fi

. build/envsetup.sh
breakfast $TARGET_DEVICE

# Set parameters
export ARCH=arm
#exort PLATFORM=arm-unknown-linux-androideabi
export PLATFORM=arm-linux-androideabi
export CROSS_COMPILE=${PLATFORM}-
export GCC_VERSION=7.x
#export PATH=$HOME/x-tools/${PLATFORM}/bin:$PATH
export PATH=${ANDROID_BUILD_TOP}/prebuilts/gcc/${HOST_OS}-x86/${ARCH}/${CROSS_COMPILE}${GCC_VERSION}/bin:$PATH

# CCache
export USE_CCACHE=1

# build
cd $ANDROID_PRODUCT_OUT/obj/KERNEL_OBJ
make mrproper
make lineageos_rhine_${TARGET_DEVICE}_row_defconfig
./source/scripts/kconfig/merge_config.sh -O ./ .config ./source/arch/arm/configs/shunodroid_defconfig
make -j`nproc`

# Assembling the boot.img
if [ $? -eq 0 ]
then
    mkbootimg \
	--kernel arch/arm/boot/zImage-dtb \
	--ramdisk ${ANDROID_PRODUCT_OUT}/ramdisk.img \
	--cmdline "console=ttyHSL0,115200,n8 androidboot.hardware=qcom user_debug=23 msm_rtb.filter=0x3b7 ehci-hcd.park=3 androidboot.bootdevice=msm_sdcc.1 vmalloc=300M dwc3.maximum_speed=high dwc3_msm.prop_chg_detect=Y" \
	--base 0x00000000 \
	--pagesize 2048 \
	--ramdisk_offset 0x02000000 --tags_offset 0x01E00000 \
	--output ${ANDROID_PRODUCT_OUT}/boot_shunodroid.img

    echo "Build successful!"
fi

make mrproper
