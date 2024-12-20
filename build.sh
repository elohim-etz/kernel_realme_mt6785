#!/bin/bash

function compile()
{
rm -rf AnyKernel
rm -rf KernelSU
source ~/.bashrc && source ~/.profile
export LC_ALL=C && export USE_CCACHE=1
ccache -M 100G
export ARCH=arm64
export KBUILD_BUILD_USER="elohim-etz"
if [ ! -d "clang" ]; then
        wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/mast>
        mkdir clang && tar -xf aosp-clang.tar.gz -C clang && rm -rf aosp-clang.tar.gz
fi
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android>
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9>
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s v0.9.5

[ -d "out" ] && rm -rf out || mkdir -p out

make O=out ARCH=arm64 RM6785_defconfig

PATH="${PWD}/clang/bin:${PATH}:${PWD}/los-4.9-32/bin:${PATH}:${PWD}/los-4.9-64/bin:${PATH}" \
make -j$(nproc --all) O=out \
                        ARCH=$ARCH \
                        CC="clang" \
                        CLANG_TRIPLE=aarch64-linux-gnu- \
                        CROSS_COMPILE="${PWD}/los-4.9-64/bin/aarch64-linux-android-" \
                        CROSS_COMPILE_ARM32="${PWD}/los-4.9-32/bin/arm-linux-androideabi-" \
                        LLVM=1 \
                        LD=ld.lld \
                        AR=llvm-ar \
                        NM=llvm-nm \
                        OBJCOPY=llvm-objcopy \
                        OBJDUMP=llvm-objdump \
                        STRIP=llvm-strip \
                        CONFIG_NO_ERROR_ON_MISMATCH=y
}

function rclone_upload()
{
    d=$(date "+%d%m%Y")
    git clone --depth=1 https://github.com/elohim-etz/AK3.git -b takoyaki AnyKernel
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
    cd AnyKernel
    zip -r9 TakoYaki-$d-RM6785-R1-ksu.zip *
    rclone copy TakoYaki-R1.zip drive:/Kernel
}

compile
rclone_upload
