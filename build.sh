#!/bin/bash
#Abort on Errors
set -e

echo "/// Checking for gcc, clang and out folder ///"
echo " "

if [ -e /home/ultra/prebuilts/gcc ]
then
   echo "** You already have gcc cloned **"
   echo " "
   echo " "
else
   echo "Cloning gcc"
   git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 /home/ultra/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
   echo " "
   echo "Cloned gcc"
   echo " "
   echo " "
fi

if [ -e /home/ultra/prebuilts/clang ]
then
   echo "** You already have clang cloned **"
   echo " "
   echo " "
else
   echo "Cloning clang"
   git clone https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-5696680 clang
   echo " "
   echo "Cloned clang"
   echo " "
   echo " "
fi

if [ -e /home/ultra/MjolnirKernels ]
then
   echo "** MjolnirKernels folder exists **"
   echo " "
   echo " "
else
   mkdir /home/ultra/MjolnirKernels
   echo "** MjolnirKernels folder not exists. Created **"
   echo " "
   echo " "
fi

DATE_POSTFIX=$(date +"%Y%m%d%H%M%S")

## Copy this script inside the kernel directory
KERNEL_DIR=$PWD
KERNEL_TOOLCHAIN=/home/ultra/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
CLANG_TOOLCHAIN=/home/ultra/prebuilts/clang/bin/clang-9
KERNEL_DEFCONFIG=sanders_defconfig
DTBTOOL=$KERNEL_DIR/Dtbtool/
ANY_KERNEL3_DIR=$KERNEL_DIR/AnyKernel3/
KERNEL=Mjölnir-Kernel
TYPE=HMP
ZIP_DIR=$KERNEL_DIR/AnyKernel3
FINAL_KERNEL_ZIP=$KERNEL-$TYPE-$DATE_POSTFIX.zip
# Speed up build process
MAKE="./makeparallel"

BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo "// Setting Toolchain //"
export CROSS_COMPILE=$KERNEL_TOOLCHAIN
export ARCH=arm64
export SUBARCH=arm64

# Clean build always lol
echo "// Cleaning //"
make clean && make mrproper && rm -rf out/

echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "          BUILDING MJÖLNIR KERNEL          "
echo -e "***********************************************$nocol"
make $KERNEL_DEFCONFIG O=out
make -j8 CC=$CLANG_TOOLCHAIN CLANG_TRIPLE=aarch64-linux-gnu- O=out

echo -e "$blue***********************************************"
echo "          GENERATING DT.img          "
echo -e "***********************************************$nocol"
$DTBTOOL/dtbToolCM -2 -o $KERNEL_DIR/out/arch/arm64/boot/dtb -s 2048 -p $KERNEL_DIR/out/scripts/dtc/ $KERNEL_DIR/out/arch/arm64/boot/dts/qcom/

echo "// Verify Image.gz & dtb //"
ls $KERNEL_DIR/out/arch/arm64/boot/Image.gz
ls $KERNEL_DIR/out/arch/arm64/boot/dtb

#Anykernel 2 time!!
echo "// Verifying AnyKERNEL3 Directory //"
ls $ANY_KERNEL3_DIR
echo "// Removing leftovers //"
rm -rf $ANY_KERNEL3_DIR/dtb
rm -rf $ANY_KERNEL3_DIR/Image.gz
rm -rf $ANY_KERNEL3_DIR/$FINAL_KERNEL_ZIP

echo "// Copying Image.gz //"
cp $KERNEL_DIR/out/arch/arm64/boot/Image.gz $ANY_KERNEL3_DIR/
echo "// Copying dtb //"
cp $KERNEL_DIR/out/arch/arm64/boot/dtb $ANY_KERNEL3_DIR/
echo "// Copying modules //"
mkdir -p AnyKernel3/modules/vendor/lib/modules
[ -e "$KERNEL_DIR/out/drivers/misc/moto-dtv-fc8300/isdbt.ko" ] && cp $KERNEL_DIR/out/drivers/misc/moto-dtv-fc8300/isdbt.ko $ZIP_DIR/modules/vendor/lib/modules || echo "DTV module not found..."

echo "// Time to zip up! //"
cd $ANY_KERNEL3_DIR/
zip -r9 $FINAL_KERNEL_ZIP * -x README $FINAL_KERNEL_ZIP
cp $KERNEL_DIR/AnyKernel3/$FINAL_KERNEL_ZIP /home/ultra/MjolnirKernels/$FINAL_KERNEL_ZIP

echo "// Good Bye!! //"
cd $KERNEL_DIR
rm -rf arch/arm64/boot/dtb
rm -rf $ANY_KERNEL3_DIR/$FINAL_KERNEL_ZIP
rm -rf AnyKernel3/Image.gz
rm -rf AnyKernel3/dtb
rm -rf $KERNEL_DIR/out/
rm -rf AnyKernel3/modules/vendor/lib/modules/*.ko
rm -rf AnyKernel3/modules/vendor/lib/modules
echo "MjolnirKernels/($FINAL_KERNEL_ZIP)"
echo "Goobye"

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
