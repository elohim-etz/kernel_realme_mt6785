#!/bin/bash

function compile()
{
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64
export DTC_EXT=dtc

[ -d "out" ] && rm -rf out || mkdir -p out

make mrproper

make O=out ARCH=arm64 RM6785_defconfig

PATH="${PWD}/clang/bin:${PATH}:${PWD}/los-4.9-32/bin:${PATH}:${PWD}/los-4.9-64/bin:${PATH}" \
make -j$(nproc --all) O=out \
                        ARCH=$ARCH \
                        CC="clang" \
                        CLANG_TRIPLE=aarch64-linux-gnu- \
                        CROSS_COMPILE="/home/imnaveenbisht/kernel/los-4.9-64/bin/aarch64-linux-android-" \
                        CROSS_COMPILE_ARM32="/home/imnaveenbisht/kernel/los-4.9-32/bin/arm-linux-androideabi-" \
            		LLVM=1 \
                        LD=ld.lld \
                        AR=llvm-ar \
                        NM=llvm-nm \
                        OBJCOPY=llvm-objcopy \
                        OBJDUMP=llvm-objdump \
                        STRIP=llvm-strip \
                        CONFIG_NO_ERROR_ON_MISMATCH=y
}

compile
