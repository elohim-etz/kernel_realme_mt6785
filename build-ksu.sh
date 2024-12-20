#!/bin/bash

# Copyright (C) 2024 psionicprjkt

compile_kernel() {
    # compile_kernel
    export ARCH=arm64
    make O=out ARCH=arm64 RM6785_defconfig

    # Generate profile data during the first compilation
    PATH="${PWD}/clang/bin:${PWD}/arm64:${PWD}/arm32:${PATH}" \
    make -j"$(nproc --all)" O=out \
        LLVM=1 \
        LLVM_IAS=1 \
        ARCH=arm64 \
        CC="clang" \
        LD=ld.lld \
        STRIP=llvm-strip \
        AS=llvm-as \
        AR=llvm-ar \
        NM=llvm-nm \
        OBJCOPY=llvm-objcopy \
        OBJDUMP=llvm-objdump \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE="${PWD}/arm64/aarch64-linux-android-" \
        CROSS_COMPILE_ARM32="${PWD}/arm32/arm-linux-androideabi-" \
        CONFIG_NO_ERROR_ON_MISMATCH=y \
        CFLAGS="-Wno-pragma-messages"
}

setup_kernel_release() {
    # setup_kernel_release
    d=$(date "+%d%m%Y")
    git clone --depth=1 https://github.com/elohim-etz/AK3.git -b takoyaki AnyKernel
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
    cd AnyKernel
    zip -r9 TakoYaki-$d-RM6785-R1.zip *
}

compile_kernel
setup_kernel_release

