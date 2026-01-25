#!/bin/bash

# 遇到错误立即停止
set -e

# --- 配置参数 ---
LIBPSL_REPO="https://github.com/rockdaboot/libpsl.git"
BUILD_DIR="build_msvc"
INSTALL_DIR="libpsl_dist"
ZIP_NAME="libpsl_msvc_x64_static.zip"

echo "=== 开始克隆 libpsl 源码 ==="
if [ ! -d "libpsl" ]; then
    git clone --recursive $LIBPSL_REPO libpsl
fi
cd libpsl

# --- 准备构建目录 ---
echo "=== 清理并创建构建目录 ==="
rm -rf $BUILD_DIR
rm -rf $INSTALL_DIR
mkdir $BUILD_DIR
mkdir $INSTALL_DIR


# --- 核心修复：排除 Git 自带的干扰项 ---
# 找到 Git/usr/bin 路径并将其从当前 PATH 中移除，避免 link.exe 冲突
export PATH=$(echo "$PATH" | sed -e 's/:\/usr\/bin//g' -e 's/:\/bin//g' -e 's/C:\\Program Files\\Git\\usr\\bin//g')

# 确保 MSVC 路径在最前面（通常 ilammy/msvc-dev-cmd 已经做好了，这里是双重保险）
echo "Current Linker Path: $(which link.exe || echo 'Not found in current bash path, good.')"
# --- 核心编译步骤 ---
# 注意：这里使用 Meson，因为 libpsl 官方推荐 MSVC 使用 Meson + Ninja
echo "=== 配置工程 (Static Release) ==="
# -Ddefault_library=static 控制生成静态库
# -Druntime_library=release 控制使用 /MT (如果不设置，默认可能是 /MD)
meson setup $BUILD_DIR \
    --buildtype=release \
    --default-library=static \
    --prefix="$(pwd)/$INSTALL_DIR" \
    -Db_vscrt=mt \
    -Dtests=false

echo "=== 开始编译与安装 ==="
meson compile -C $BUILD_DIR
meson install -C $BUILD_DIR

# --- 打包产物 ---
echo "=== 整理产物并打包 ==="
# 移除不需要的 pkgconfig 目录（可选）
# rm -rf "$INSTALL_DIR/lib/pkgconfig"

echo "=== 打包产物 ==="
if command -v 7z >/dev/null 2>&1; then
    echo "zip using zip"
    7z a -tzip "../$ZIP_NAME" "./$INSTALL_DIR/*"
else
    # 备选方案：调用 PowerShell
    echo "zip using powershell"
    powershell.exe -Command "Compress-Archive -Path './$INSTALL_DIR/*' -DestinationPath '../$ZIP_NAME' -Force"
fi

cd ..