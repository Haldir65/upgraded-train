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

# --- 核心编译步骤 ---
# 注意：这里使用 Meson，因为 libpsl 官方推荐 MSVC 使用 Meson + Ninja
echo "=== 配置工程 (Static Release) ==="
# -Ddefault_library=static 控制生成静态库
# -Druntime_library=release 控制使用 /MT (如果不设置，默认可能是 /MD)
meson setup $BUILD_DIR \
    --buildtype=release \
    --default-library=static \
    --prefix="$(pwd)/$INSTALL_DIR" \
    -Druntime_library=release \
    -Dtests=false

echo "=== 开始编译与安装 ==="
meson compile -C $BUILD_DIR
meson install -C $BUILD_DIR

# --- 打包产物 ---
echo "=== 整理产物并打包 ==="
# 移除不需要的 pkgconfig 目录（可选）
# rm -rf "$INSTALL_DIR/lib/pkgconfig"

if command -v zip >/dev/null 2>&1; then
    zip -r "../$ZIP_NAME" "$INSTALL_DIR"/*
    echo "=== 成功完成！打包文件为: $ZIP_NAME ==="
else
    echo "未发现 zip 命令，仅完成编译，产物位于: $INSTALL_DIR"
fi

cd ..