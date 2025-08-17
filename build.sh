#!/bin/bash

function setup_env()
{
    git clone https://github.com/akhilnarang/scripts env
    bash env/setup/android_build_env.sh
}

echo "On upstream-xx branch"

function compile()
{
rm -rf out
rm -rf AnyKernel
source ~/.bashrc && source ~/.profile
export LC_ALL=C && export USE_CCACHE=1
export ARCH=arm64
export KBUILD_BUILD_USER="elohim-etz"
if [ ! -d "clang" ]; then
    wget -q https://android.googlesource.com/platform//prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r547379.tar.gz -O "clang.tar.gz"
    mkdir clang && tar -xf clang.tar.gz -C clang && rm -rf clang.tar.gz
fi
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 los-4.9-64
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 los-4.9-32
curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s susfs-main

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
                        CONFIG_NO_ERROR_ON_MISMATCH=y \
                        CONFIG_NO_ERROR_ON_MISMATCH=y 2>&1 | tee error.log
}

function zip_kernel()
{
    d=$(date "+%d%m%Y")
    git clone --depth=1 https://github.com/elohim-etz/AK3.git -b mikuchan AnyKernel
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
    cd AnyKernel
    zip -r9 MikuChan-SukiSU-4.14.356-$d-RM6785-ksu.zip *
}

setup_env
compile
zip_kernel