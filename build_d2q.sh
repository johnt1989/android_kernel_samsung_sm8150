#!/bin/bash

# Variables
DIR=`readlink -f .`;
PARENT_DIR=`readlink -f ${DIR}/..`;

export PLATFORM_VERSION=12
export ANDROID_MAJOR_VERSION=s
BUILD_CROSS_COMPILE=$PARENT_DIR/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=$PARENT_DIR/llvm-arm-toolchain-ship-10.0/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="LOCALVERSION=-Doc714"

export v=$(pwd)/arch/arm64/configs/doc_d2q_defconfig
export VARIANT=d2q

toolchain()
{
  if [ ! -d $PARENT_DIR/aarch64-linux-android-4.9 ]; then
    git clone --branch android-9.0.0_r59 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 $PARENT_DIR/aarch64-linux-android-4.9
  fi
}

llvm()
{
  if [ ! -d $PARENT_DIR/llvm-arm-toolchain-ship-10.0 ]; then
    git clone https://github.com/proprietary-stuff/llvm-arm-toolchain-ship-10.0 $PARENT_DIR/llvm-arm-toolchain-ship-10.0
  fi
}

clean()
{
  make $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN clean 
  make $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN mrproper
  [ -d "out" ] && rm -rf out
}

build()
{
  [ ! -d "out" ] && mkdir out
  make -j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN doc_d2q_defconfig
  make -j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN

  [ -e out/arch/arm64/boot/Image.gz ] && cp out/arch/arm64/boot/Image.gz $(pwd)/out/Image.gz
  if [ -e out/arch/arm64/boot/Image.gz-dtb ]; then
    cp out/arch/arm64/boot/Image.gz-dtb $(pwd)/out/Image.gz-dtb

    DTBO_FILES=$(find $(pwd)/out/arch/arm64/boot/dts/samsung/davinci/ -name sm8150-sec-d2q-overlay-r*.dtbo)
    cat $(pwd)/out/arch/arm64/boot/dts/qcom/*.dtb > $(pwd)/out/dtb.img
    $(pwd)/tools/mkdtimg create $(pwd)/out/dtbo.img --page_size=4096 $(pwd)/out/arch/arm64/boot/dts
  fi
}

anykernel3()
{
  if [ ! -d $PARENT_DIR/AnyKernel3 ]; then
    git clone https://github.com/osm0sis/AnyKernel3 $PARENT_DIR/AnyKernel3
  fi
  if [ -e out/arch/arm64/boot/Image.gz-dtb ]; then
    cp out/arch/arm64/boot/Image.gz-dtb $PARENT_DIR/AnyKernel3/zImage
  if [ -e $(pwd)out/dtb.img ]; then
    cp $(pwd)/out/dtb.img $PARENT_DIR/AnyKernel3/dtb.img
  if [ -e $(pwd)out/dtbo.img ]; then
    cp $(pwd)/out/dtbo.img $PARENT_DIR/AnyKernel3/dtbo.img
  fi
  cd $PARENT_DIR/AnyKernel3
  git reset --hard
  sed -i "s/ExampleKernel by osm0sis/d2q kernel by Doc714/g" anykernel.sh
  sed -i "s/=maguro/=d2q/g" anykernel.sh
  sed -i "s/=toroplus/=/g" anykernel.sh
  sed -i "s/=toro/=/g" anykernel.sh
  sed -i "s/=tuna/=/g" anykernel.sh
  sed -i "s/omap\/omap_hsmmc\.0\/by-name\/boot/soc\/1d84000\.ufshc\/by-name\/boot/g" anykernel.sh
  sed -i "s/backup_file/#backup_file/g" anykernel.sh
  sed -i "s/replace_string/#replace_string/g" anykernel.sh
  sed -i "s/insert_line/#insert_line/g" anykernel.sh
  sed -i "s/append_file/#append_file/g" anykernel.sh
  sed -i "s/patch_fstab/#patch_fstab/g" anykernel.sh
  zip -r9 $PARENT_DIR/d2q_kernel.zip * -x .git README.md *placeholder
  cd $DIR
}

toolchain
llvm
clean
build
anykernel3