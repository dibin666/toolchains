#!/bin/bash

# 添加 Anykernel3
rm -rf AnyKernel3
git clone --depth=1 https://github.com/dibin666/AnyKernel3 -b lmi

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
current_time=$(date +"%Y-%m-%d-%H-%S")

# AnyKernel3 路径
ANYKERNEL3_DIR=$PWD/AnyKernel3/

# 编译完成后内核名字
FINAL_KERNEL_ZIP=AnyKernel3-perf-lmi-KernelSU-${current_time}.zip

# 内核工作目录
export KERNEL_DIR=$(pwd)

# 内核 defconfig 文件
export KERNEL_DEFCONFIG=vendor/lmi_user_defconfig

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
				NM=llvm-nm \
    				AR=llvm-ar \
        			OBJCOPY=llvm-objcopy \
        			OBJDUMP=llvm-objdump \
        			STRIP=llvm-strip \
				LD=ld.lld"

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
# cp $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP ../../out

echo "编译耗时：$elapsed_time 秒"

# 上传打包好的 Zip 文件到 Telegram 频道
# 设置Telegram Bot的API令牌和频道ID
TOKEN=""
CHANNEL_ID=""

# 要上传的文件路径
FILE_PATH="$FINAL_KERNEL_ZIP"

# 要发送的消息内容
MESSAGE="LMI kernel build successfully!"

# 发送API请求，上传文件到Teleram频道
curl -F chat_id="$CHANNEL_ID" -F document=@"$FILE_PATH" "https://api.telegram.org/bot$TOKEN/sendDocument"

# 发送API请求，发送消息到Telegram频道
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d "chat_id=$CHANNEL_ID" \
    -d "text=$MESSAGE"

# 清理目录
cd ..
rm -rf AnyKernel3
rm -rf KernelSU
rm -rf out
