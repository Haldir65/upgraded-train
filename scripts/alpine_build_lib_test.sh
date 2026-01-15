#!/bin/sh

# 设置安装目录的绝对路径
ROOT_DIR=$(pwd)
BUILD_DIR="${ROOT_DIR}/build"
INSTALL_DIR="${BUILD_DIR}/grpc_install"
GRPC_SRC_DIR="${ROOT_DIR}/grpc"


function _build_grpc(){
    local grpc_version=1.76.0
    # 1. 克隆 gRPC 源码 (如果不存在)
    if [ ! -d "$GRPC_SRC_DIR" ]; then
        echo "--- 正在克隆 gRPC 源码 ---"
        git clone --recurse-submodules -b v${grpc_version} --depth 1 --shallow-submodules https://github.com/grpc/grpc.git "$GRPC_SRC_DIR"
    fi


    # --- 核心修复：更精确的 RE2 源码补丁 ---
    echo "--- 正在为 RE2 源码打补丁 ---"

    # 1. 在头文件注入缺失的 <cstdint>
    sed -i '1i #include <cstdint>' "$GRPC_SRC_DIR/third_party/re2/util/pcre.h"

    # 2. 将变量 hit_limit_ 声明为 mutable (解决 const 函数内修改变量的错误)
    # 使用 \< 和 \> 确保只匹配单词，不匹配函数名
    sed -i 's/\<bool hit_limit_;\>/mutable bool hit_limit_;/g' "$GRPC_SRC_DIR/third_party/re2/util/pcre.h"

    # 3. 修复代码中变量名引用不一致的问题 (仅在赋值语句中替换)
    # 这一步将 hit_limit_ = ... 相关的错误引用修正
    sed -i 's/\<HitLimit\>/hit_limit_/g' "$GRPC_SRC_DIR/third_party/re2/util/pcre.cc"

    # 4. 【关键修正】恢复被误伤的函数名
    # 上一步会把 ClearHitLimit 变成 Clearhit_limit_，我们需要把它改回来
    sed -i 's/Clearhit_limit_/ClearHitLimit/g' "$GRPC_SRC_DIR/third_party/re2/util/pcre.cc"
    sed -i 's/Clearhit_limit_/ClearHitLimit/g' "$GRPC_SRC_DIR/third_party/re2/util/pcre.h"

    # 2. 清理并创建目录
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$INSTALL_DIR"

    cd "$BUILD_DIR"

    # 3. 配置 CMake
    # 我们强制指定使用 'module' 模式，让 gRPC 编译它自带的第三方库，确保全静态链接
    echo "--- 正在配置 CMake ---"
    cmake "$GRPC_SRC_DIR" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
        -DgRPC_INSTALL=ON \
        -DgRPC_BUILD_TESTS=OFF \
        -DgRPC_SSL_PROVIDER=module \
        -DgRPC_ZLIB_PROVIDER=module \
        -DgRPC_CARES_PROVIDER=module \
        -DgRPC_RE2_PROVIDER=module \
        -DRE2_BUILD_TESTING=OFF \
        -DgRPC_PROTOBUF_PROVIDER=module \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON

    # 5. 执行编译
    echo "--- 正在编译 ---"
    cmake --build . --config Release -j$(nproc)

    # 6. 执行安装 (替换之前的 ninja install)
    echo "--- 正在执行安装 ---"
    cmake --install . --prefix "$INSTALL_DIR"

    rm -rf $INSTALL_DIR/share

    # 7. 瘦身：移除静态库中的调试符号
    echo "--- 正在清理调试符号 ---"
    find "$INSTALL_DIR/lib" -name "*.a" -exec strip --strip-debug {} +


    case "$(uname -m)" in
    aarch64|arm64)
        ARCH_SUFFIX="arm64"
        ;;
    x86_64|amd64)
        ARCH_SUFFIX="x86_64"
        ;;
    *)
        ARCH_SUFFIX="unknown"
        ;;
    esac

    # 5. 打包安装后的目录
    cd "$BUILD_DIR"
    echo "--- 正在打包 grpc_install_${ARCH_SUFFIX}.zip ---"
    # 使用 -r 递归打包整个目录
    zip -r ../grpc_install_${ARCH_SUFFIX}.zip grpc_install

    # 6. 上传到 HTTP Server
    cd "$ROOT_DIR"
    UPLOAD_URL="https://${UPLOAD_API_URL}"

    echo "--- 正在上传 grpc_install_${ARCH_SUFFIX}.zip 到 UPLOAD_URL ---"
    curl -X POST \
        -F "file=@grpc_install_${ARCH_SUFFIX}.zip" \
        -H "Content-Type: multipart/form-data" \
        -H "authority: 3242asasdas" \
        "$UPLOAD_URL"

    if [ $? -eq 0 ]; then
        echo -e "\n✅ gRPC 静态库编译并上传成功!"
    else
        echo -e "\n❌ 上传失败，请检查网络。"
    fi
}



function _build_grpc_openwrt(){
      local grpc_version=1.76.0
    # 1. 克隆 gRPC 源码 (如果不存在)
    if [ ! -d "$GRPC_SRC_DIR" ]; then
        echo "--- 正在克隆 gRPC 源码 ---"
        git clone --recurse-submodules -b v${grpc_version} --depth 1 --shallow-submodules https://github.com/grpc/grpc.git "$GRPC_SRC_DIR"
    fi


    # --- 核心修复：更精确的 RE2 源码补丁 ---
    echo "--- 正在为 RE2 源码打补丁 ---"

    # 1. 在头文件注入缺失的 <cstdint>
    sed -i '1i #include <cstdint>' "$GRPC_SRC_DIR/third_party/re2/util/pcre.h"

    # 2. 将变量 hit_limit_ 声明为 mutable (解决 const 函数内修改变量的错误)
    # 使用 \< 和 \> 确保只匹配单词，不匹配函数名
    sed -i 's/\<bool hit_limit_;\>/mutable bool hit_limit_;/g' "$GRPC_SRC_DIR/third_party/re2/util/pcre.h"

    # 3. 修复代码中变量名引用不一致的问题 (仅在赋值语句中替换)
    # 这一步将 hit_limit_ = ... 相关的错误引用修正
    sed -i 's/\<HitLimit\>/hit_limit_/g' "$GRPC_SRC_DIR/third_party/re2/util/pcre.cc"

    # 4. 【关键修正】恢复被误伤的函数名
    # 上一步会把 ClearHitLimit 变成 Clearhit_limit_，我们需要把它改回来
    sed -i 's/Clearhit_limit_/ClearHitLimit/g' "$GRPC_SRC_DIR/third_party/re2/util/pcre.cc"
    sed -i 's/Clearhit_limit_/ClearHitLimit/g' "$GRPC_SRC_DIR/third_party/re2/util/pcre.h"

    # 2. 清理并创建目录
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$INSTALL_DIR"

    cd "$BUILD_DIR"

    # 3. 配置 CMake
    # 我们强制指定使用 'module' 模式，让 gRPC 编译它自带的第三方库，确保全静态链接
    echo "--- 正在配置 CMake ---"
    cmake "$GRPC_SRC_DIR" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
        -DgRPC_INSTALL=ON \
        -DgRPC_BUILD_TESTS=OFF \
        -DgRPC_SSL_PROVIDER=module \
        -DgRPC_ZLIB_PROVIDER=module \
        -DgRPC_CARES_PROVIDER=module \
        -DgRPC_RE2_PROVIDER=module \
        -DRE2_BUILD_TESTING=OFF \
        -DgRPC_PROTOBUF_PROVIDER=module \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON

    # 5. 执行编译
    echo "--- 正在编译 ---"
    cmake --build . --config Release -j$(nproc)

    # 6. 执行安装 (替换之前的 ninja install)
    echo "--- 正在执行安装 ---"
    cmake --install . --prefix "$INSTALL_DIR"

    rm -rf $INSTALL_DIR/share

    # 7. 瘦身：移除静态库中的调试符号
    echo "--- 正在清理调试符号 ---"
    find "$INSTALL_DIR/lib" -name "*.a" -exec strip --strip-debug {} +


    case "$(uname -m)" in
    aarch64|arm64)
        ARCH_SUFFIX="arm64"
        ;;
    x86_64|amd64)
        ARCH_SUFFIX="x86_64"
        ;;
    *)
        ARCH_SUFFIX="unknown"
        ;;
    esac

    # 5. 打包安装后的目录
    cd "$BUILD_DIR"
    echo "--- 正在打包 grpc_install_${ARCH_SUFFIX}.zip ---"
    # 使用 -r 递归打包整个目录
    zip -r ../grpc_install_${ARCH_SUFFIX}.zip grpc_install

    # 6. 上传到 HTTP Server
    cd "$ROOT_DIR"
    UPLOAD_URL="https://${UPLOAD_API_URL}"

    echo "--- 正在上传 grpc_install_${ARCH_SUFFIX}.zip 到 UPLOAD_URL ---"
    curl -X POST \
        -F "file=@grpc_install_${ARCH_SUFFIX}.zip" \
        -H "Content-Type: multipart/form-data" \
        -H "authority: 3242asasdas" \
        "$UPLOAD_URL"

    if [ $? -eq 0 ]; then
        echo -e "\n✅ gRPC 静态库编译并上传成功!"
    else
        echo -e "\n❌ 上传失败，请检查网络。"
    fi
}

function main(){
    _build_grpc
}


main