#!/bin/bash

ARCH=arm64

export PLATFORM_VERSION=12
export ANDROID_MAJOR_VERSION=s
BUILD_CROSS_COMPILE=$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=$(pwd)/toolchain/llvm-arm-toolchain-ship/10.0/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="LOCALVERSION=-Doc714"

DTS_DIR=$(pwd)/out/arch/$ARCH/boot/dts

export PATH=$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin:$$(pwd)/toolchain/llvm-arm-toolchain-ship/10.0/bin:$PATH

make $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN clean 
make $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN mrproper
rm -rf out

mkdir out
make -j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN doc_d2q_defconfig
make -j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN

[ -e out/arch/arm64/boot/Image.gz ] && cp out/arch/arm64/boot/Image.gz $(pwd)/out/Image.gz
if [ -e out/arch/arm64/boot/Image.gz-dtb ]; then
	cp out/arch/arm64/boot/Image.gz-dtb $(pwd)/out/Image.gz-dtb

	DTBO_FILES=$(find ${DTS_DIR}/samsung/davinci -name sm8150-sec-d2q-*-r*.dtbo)
	cat ${DTS_DIR}/qcom/*.dtb > $(pwd)/out/dtb.img
	$(pwd)/tools/mkdtimg create $(pwd)/out/dtbo.img --page_size=4096 ${DTBO_FILES}

	git clone https://github.com/osm0sis/AnyKernel3 $(pwd)/out/AnyKernel3
	cd out/AnyKernel3
	cp out/arch/arm64/boot/Image.gz-dtb $(pwd)/out/AnyKernel3/zImage
	git reset --hard
	sed -i "s/ExampleKernel by osm0sis/d2q kernel by Doc714/g" anykernel.sh
	sed -i "s/=maguro/=d2q/g" anykernel.sh
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
	zip -r9 d2q_kernel.zip *
fi