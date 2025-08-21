#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

function log() {
    echo -e "${GREEN}[*] $1${NC}"
}

function error_exit() {
    echo -e "${RED}[!] $1${NC}" >&2
    exit 1
}

function setup_env() {
    log "Setting up environment..."

    if [ ! -d "env" ]; then
        git clone https://github.com/akhilnarang/scripts env || error_exit "Failed to clone environment scripts."
    fi

    bash env/setup/android_build_env.sh || error_exit "Failed to set up Android build environment."
}

function download_toolchains() {
    log "Downloading and setting up toolchains..."

    if [ ! -d "clang" ]; then
        wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r547379.tar.gz -O clang.tar.gz \
            && mkdir clang \
            && tar -xf clang.tar.gz -C clang \
            && rm -f clang.tar.gz || error_exit "Failed to download or extract clang."
    fi

    [ ! -d "los-4.9-64" ] && git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 los-4.9-64
    [ ! -d "los-4.9-32" ] && git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 los-4.9-32
}

function setup_kernelsu() {
    log "Setting up KernelSU..."
    curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s susfs-main || error_exit "KernelSU setup failed."
}

function compile_kernel() {
    log "Starting kernel compilation..."

    rm -rf out AnyKernel
    mkdir -p out

    source ~/.bashrc || true
    source ~/.profile || true

    export LC_ALL=C
    export USE_CCACHE=1
    export ARCH=arm64
    export KBUILD_BUILD_USER="elohim-etz"

    make O=out ARCH=arm64 RM6785_defconfig

    PATH="${PWD}/clang/bin:${PWD}/los-4.9-32/bin:${PWD}/los-4.9-64/bin:${PATH}"

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
        2>&1 | tee error.log || error_exit "Kernel build failed. Check error.log"
}

function zip_kernel() {
    log "Zipping kernel..."

    DATE=$(date "+%d%m%Y")
    KERNEL_IMAGE="out/arch/arm64/boot/Image.gz-dtb"

    if [ ! -f "$KERNEL_IMAGE" ]; then
        error_exit "Kernel image not found at $KERNEL_IMAGE"
    fi

    git clone --depth=1 https://github.com/elohim-etz/AK3.git -b mikuchan AnyKernel || error_exit "Failed to clone AnyKernel3"
    cp "$KERNEL_IMAGE" AnyKernel || error_exit "Failed to copy kernel image"
    cd AnyKernel || exit
    zip -r9 Miku-4.14.356-SukiSU-${DATE}-RM6785-ksu.zip * || error_exit "Zipping failed"
    log "Kernel zip created: AnyKernel/Miku-4.14.356-SukiSU-${DATE}-RM6785-ksu.zip"
}

function main() {
    setup_env
    download_toolchains
    setup_kernelsu
    compile_kernel
    zip_kernel
}

main "$@"
