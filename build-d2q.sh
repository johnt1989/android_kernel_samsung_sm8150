#!/bin/bash

KDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

export PLATFORM_VERSION=12
export ANDROID_MAJOR_VERSION=s
ARCH=arm64
BUILD_CROSS_COMPILE=$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=$(pwd)/toolchain/llvm-arm-toolchain-ship-10.0/bin/clang
DTS_DIR=$(pwd)/out/arch/$ARCH/boot/dts
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="LOCALVERSION=-doc714"

export PATH="$KDIR/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin:$KDIR/toolchain/llvm-arm-toolchain-ship-10.0/bin:${PATH}"

make $KERNEL_MAKE_ENV \
	ARCH=arm64 \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE \
	REAL_CC=$KERNEL_LLVM_BIN \
	CLANG_TRIPLE=$CLANG_TRIPLE \
	CFP_CC=$KERNEL_LLVM_BIN clean
make $KERNEL_MAKE_ENV \
	ARCH=arm64 \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE \
	REAL_CC=$KERNEL_LLVM_BIN \
	CLANG_TRIPLE=$CLANG_TRIPLE \
	CFP_CC=$KERNEL_LLVM_BIN mrproper

if [ ! -d "out" ]; then
	mkdir out \
		make -j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV \
		ARCH=arm64 \
		CROSS_COMPILE=$BUILD_CROSS_COMPILE \
		REAL_CC=$KERNEL_LLVM_BIN \
		CLANG_TRIPLE=$CLANG_TRIPLE \
		CFP_CC=$KERNEL_LLVM_BIN doc714_d2q_defconfig

	make -j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV \
		ARCH=arm64 \
		CROSS_COMPILE=$BUILD_CROSS_COMPILE \
		REAL_CC=$KERNEL_LLVM_BIN \
		CLANG_TRIPLE=$CLANG_TRIPLE \
		CFP_CC=$KERNEL_LLVM_BIN

	[ -e $KDIR/out/arch/arm64/boot/Image.gz ] && cp $KDIR/out/arch/arm64/boot/Image.gz $(pwd)/out/Image.gz
	if [ -e $KDIR/out/arch/arm64/boot/Image.gz-dtb ]; then
		cp $KDIR/out/arch/arm64/boot/Image.gz-dtb $(pwd)/out/Image.gz-dtb

		DTBO_FILES=$(find ${DTS_DIR}/samsung/ -name sm8150-sec-sm8150-*-r*.dtbo)
		cat ${DTS_DIR}/qcom/*.dtb > $(pwd)/out/dtb.img
		$(pwd)/tools/mkdtimg create $(pwd)/out/dtbo.img --page_size=4096 ${DTBO_FILES}
	fi

	if [ ! -d $KDIR/AnyKernel3 ]; then
		git clone https://github.com/osm0sis/AnyKernel3 $KDIR/AnyKernel3
	fi

	if [ -e $KDIR/out/arch/arm64/boot/Image.gz-dtb ]; then
		cd $KDIR/AnyKernel3
		git reset --hard
		cp $KDIR/out/arch/arm64/boot/Image.gz-dtb zImage
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
		zip -r9 d2q_kernel.zip * -x .git README.md *placeholder
		cd $KDIR
	fi
fi