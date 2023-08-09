#!/bin/bash

# 添加 Anykernel3
rm -rf AnyKernel3
git clone --depth=1 https://github.com/dibin666/AnyKernel3 -b maple_dsds

# 添加 KernelSU
read -p "是否添加 KernelSU？(y/n): " choice
if [ "$choice" = "y" ]; then
  rm -rf KernelSU
  # 提示用户选择版本
  read -p "请选择版本（开发版/稳定版）：(1/0): " channel
  
  if [ "$channel" = "1" ]; then
    echo "您选择了开发版"
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main
  elif [ "$channel" = "0" ]; then
    echo "您选择了稳定版"
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
  else
    echo "无效的选择"
    exit 1
  fi
fi

# 当前时间
current_time=$(date +"%Y-%m-%d-%H-%s")

# AnyKernel3 路径
ANYKERNEL3_DIR=$PWD/AnyKernel3/

# 编译完成后内核名字
FINAL_KERNEL_ZIP=AnyKernel3-whatwursts-maple_dsds-${current_time}.zip

# 编译完内核输出目录
export OUT_PATH=/mnt/disk/out

# 内核工作目录
export KERNEL_DIR=$(pwd)

# 内核 defconfig 文件
export KERNEL_DEFCONFIG=lineage-msm8998-yoshino-maple_dsds_defconfig

# 编译临时目录，避免污染根目录
export OUT=out

# clang 和 gcc 绝对路径
export CLANG_PATH=/mnt/disk2/tool2/clang12
export PATH=${CLANG_PATH}/bin:${PATH}
export GCC_PATH=/mnt/disk2/tool2/gcc

# 编译参数
export DEF_ARGS="O=${OUT} \
				ARCH=arm64 \
                                CC=clang \
				CLANG_TRIPLE=aarch64-linux-gnu- \
				CROSS_COMPILE=${GCC_PATH}/aarch64-linux-android-4.9/bin/aarch64-linux-android- \
                                CROSS_COMPILE_ARM32=${GCC_PATH}/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- \
				LD=ld.lld "

export BUILD_ARGS="-j$(nproc --all) ${DEF_ARGS}"

# 开始编译内核
make ${DEF_ARGS} ${KERNEL_DEFCONFIG}
make ${BUILD_ARGS}

# 复制编译出的文件到 AnyKernel3 目录
if [[ -f out/arch/arm64/boot/Image.gz-dtb ]]; then
  cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3/Image.gz-dtb
elif [[ -f out/arch/arm64/boot/Image-dtb ]]; then
  cp out/arch/arm64/boot/Image-dtb AnyKernel3/Image-dtb
elif [[ -f out/arch/arm64/boot/Image.gz ]]; then
  cp out/arch/arm64/boot/Image.gz AnyKernel3/Image.gz
elif [[ -f out/arch/arm64/boot/Image ]]; then
  cp out/arch/arm64/boot/Image AnyKernel3/Image
fi

if [ -f out/arch/arm64/boot/dtbo.img ]; then
  cp out/arch/arm64/boot/dtbo.img AnyKernel3/dtbo.img
fi

# 打包内核为可刷入 Zip 文件
cd $ANYKERNEL3_DIR/
zip -r $FINAL_KERNEL_ZIP * -x README $FINAL_KERNEL_ZIP

# 复制打包好的 Zip 文件到指定的目录
cp $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP ${OUT_PATH}

# 清理目录
cd ..
rm -rf KernelSU
rm -rf AnyKernel3
rm -rf out
