#!/bin/sh
. $(dirname "$0")/functions.sh
. $(dirname "$0")/version.sh


# 设置安装目录的绝对路径
ROOT_DIR=$(pwd)
BUILD_DIR="${ROOT_DIR}/build"
INSTALL_DIR="${BUILD_DIR}/grpc_static"
GRPC_SRC_DIR="${ROOT_DIR}/grpc"
PREBUILT_DIR="${ROOT_DIR}/prebuilt"





function _build_zlib_static(){
    _green "\n  starting build zlib static \n"
    local zlib_install_dir=${PREBUILT_DIR}/zlib/${ARCH}
    mkdir -p ${BUILD_DIR}
    mkdir -p ${zlib_install_dir}
    _download_if_not_exists https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz zlib-${ZLIB_VERSION}.tar.gz
    tar xzvf zlib-${ZLIB_VERSION}.tar.gz -C ${BUILD_DIR}
    cd ${BUILD_DIR}/zlib-${ZLIB_VERSION}
    CFLAGS="-O3 -fPIC" ./configure --prefix="$zlib_install_dir" --static
    make -j8
    make install
    rm -rf ${zlib_install_dir}/share
    _green "\n  done build zlib static \n"
    _green "\n  zlib are binary can be found in ${zlib_install_dir} \n"
    tree -L 4 ${zlib_install_dir}
    cd ${ROOT_DIR}
}


function _build_openssl_static_with_zlib(){
    _green "\n  starting build zlib static \n"
    local OPENSSL_INSTALL_DIR=${PREBUILT_DIR}/openssl/${ARCH}
    local prebuilt_zlib_root=${PREBUILT_DIR}/zlib/${ARCH}
    mkdir -p ${BUILD_DIR}
    mkdir -p ${OPENSSL_INSTALL_DIR}
    _download_if_not_exists https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VERSION/openssl-$OPENSSL_VERSION.tar.gz openssl-$OPENSSL_VERSION.tar.gz
    rm -rf ${BUILD_DIR}/openssl-$OPENSSL_VERSION
    tar xzvf openssl-$OPENSSL_VERSION.tar.gz -C ${BUILD_DIR}
    cd ${BUILD_DIR}/openssl-$OPENSSL_VERSION

    # 1. 定义基础参数
    CONF_ARGS="no-shared no-docs --static"
    if [ "$PLATFORM" = "macos-arm64" ]; then
        CONF_ARGS="darwin64-arm64-cc zlib $CONF_ARGS"
    elif [ "$PLATFORM" = "linux-arm64" ]; then
        CONF_ARGS="linux-aarch64 zlib $CONF_ARGS"
    elif [ "$PLATFORM" = "linux-x64" ]; then
        CONF_ARGS="zlib $CONF_ARGS"
    fi

    ./Configure $CONF_ARGS \
    --prefix=${OPENSSL_INSTALL_DIR} \
    --openssldir=${OPENSSL_INSTALL_DIR} \
    --libdir=lib \
    --with-zlib-include=${prebuilt_zlib_root}/include \
    --with-zlib-lib=${prebuilt_zlib_root}/lib 

    make -j8
    make install_sw
    _green "\n  done build openssl static \n"
    _green "\n  openssl with zlib are binary can be found in ${OPENSSL_INSTALL_DIR} \n"
    tree -L 4 ${OPENSSL_INSTALL_DIR}
    cd ${ROOT_DIR}
}


function main(){
     mkdir -p ${PREBUILT_DIR}
    _detect_platform
    _build_zlib_static
    _build_openssl_static_with_zlib
}

main