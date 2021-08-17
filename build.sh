#!/bin/bash
#
# Compile script for SilverQueen kernel
# Copyright (C) 2020-2021 BrianScape.

SECONDS=0 # builtin bash timer
ZIPNAME="SilverQueen-santoni-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="$HOME/tc/proton-clang"
DEFCONFIG="vendor/santoni_treble_defconfig"
export KBUILD_BUILD_TIMESTAMP="$(TZ=Asia/Jakarta date)"
export PATH="$TC_DIR/bin:$PATH"

if ! [ -d "$TC_DIR" ]; then
echo "Proton clang not found! Cloning to $TC_DIR..."
if ! git clone -q --depth=1 --single-branch https://github.com/kdrag0n/proton-clang $TC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

export KBUILD_BUILD_USER=brianscape
export KBUILD_BUILD_HOST=ubuntu

if [[ $1 = "-r" || $1 = "--regen" ]]; then
make O=out ARCH=arm64 $DEFCONFIG savedefconfig
cp out/defconfig arch/arm64/configs/$DEFCONFIG
exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
if ! git clone -q https://github.com/brianscapee/AnyKernel3; then
echo -e "\nCloning AnyKernel3 repo failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
rm -f *zip
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
curl --upload-file $ZIPNAME http://transfer.sh/$ZIPNAME; echo
else
echo -e "\nCompilation failed!"
fi
