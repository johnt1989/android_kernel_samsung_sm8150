#!/bin/bash

# Variables
DIR=`readlink -f .`
OUT_DIR=$DIR/out
PARENT_DIR=`readlink -f ${DIR}/..`

CHIPSET_NAME=sm8150
export ARCH=arm64
export PLATFORM_VERSION=12
export ANDROID_MAJOR_VERSION=s
export VARIANT=d2q
BUILD_CROSS_COMPILE=$PARENT_DIR/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=$PARENT_DIR/llvm-arm-toolchain-ship-10.0/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="LOCALVERSION=-Doc714"

DTS_DIR=$OUT_DIR/arch/$ARCH/boot/dts

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
  make $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE clean 
  make $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE mrproper
  [ -d "$OUT_DIR" ] && rm -rf $OUT_DIR
}

build_kernel()
{
  [ ! -d "$OUT_DIR" ] && mkdir $OUT_DIR
  make -j$(nproc) -C $(pwd) O=$OUT_DIR $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE doc_d2q_defconfig
  make -j$(nproc) -C $(pwd) O=$OUT_DIR $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE

  [ -e $OUT_DIR/arch/arm64/boot/Image.gz ] && cp $OUT_DIR/arch/arm64/boot/Image.gz $OUT_DIR/Image.gz
  if [ -e $OUT_DIR/arch/arm64/boot/Image.gz-dtb ]; then
    cp $OUT_DIR/arch/arm64/boot/Image.gz-dtb $OUT_DIR/Image.gz-dtb

    DTBO_FILES=$(find ${DTS_DIR}/samsung/ -name ${CHIPSET_NAME}-sec-${VARIANT}-*-r*.dtbo)
    cat ${DTS_DIR}/qcom/*.dtb > $OUT_DIR/dtb.img
    $(pwd)/tools/mkdtimg create $OUT_DIR/dtbo.img --page_size=4096 ${DTBO_FILES}
  fi
}

anykernel3()
{
  if [ ! -d $PARENT_DIR/AnyKernel3 ]; then
    git clone https://github.com/osm0sis/AnyKernel3 $PARENT_DIR/AnyKernel3
  fi
  if [ -e $OUT_DIR/arch/arm64/boot/Image.gz-dtb ]; then
    cp $OUT_DIR/arch/arm64/boot/Image.gz-dtb $PARENT_DIR/AnyKernel3/zImage
    cp $OUT_DIR/dtb.img $PARENT_DIR/AnyKernel3/dtb.img
    cp $OUT_DIR/dtbo.img $PARENT_DIR/AnyKernel3/dtbo.img
    cd $PARENT_DIR/AnyKernel3
    git reset --hard
    cp $OUT_DIR/arch/arm64/boot/Image zImage
    sed -i "s/ExampleKernel by osm0sis/${VARIANT} kernel by Doc714/g" anykernel.sh
    sed -i "s/do\.devicecheck=1/do\.devicecheck=0/g" anykernel.sh
    sed -i "s/=maguro/=/g" anykernel.sh
    sed -i "s/=toroplus/=/g" anykernel.sh
    sed -i "s/=toro/=/g" anykernel.sh
    sed -i "s/=tuna/=/g" anykernel.sh
    sed -i "s/platform\/omap\/omap_hsmmc\.0\/by-name\/boot/bootdevice\/by-name\/boot/g" anykernel.sh
    sed -i "s/backup_file/#backup_file/g" anykernel.sh
    sed -i "s/replace_string/#replace_string/g" anykernel.sh
    sed -i "s/insert_line/#insert_line/g" anykernel.sh
    sed -i "s/append_file/#append_file/g" anykernel.sh
    sed -i "s/patch_fstab/#patch_fstab/g" anykernel.sh
    sed -i "s/dump_boot/split_boot/g" anykernel.sh
    sed -i "s/write_boot/flash_boot/g" anykernel.sh
    zip -r9 $PARENT_DIR/d2q_kernel.zip * -x .git README.md *placeholder
    cd $DIR
  fi
}

toolchain
llvm
clean
build_kernel
anykernel3