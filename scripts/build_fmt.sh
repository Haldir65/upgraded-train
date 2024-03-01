#!/bin/bash

. $(dirname "$0")/functions.sh


# Display all commands before executing them.
set -o errexit
set -o errtrace




function _build_fmt(){
    echo "building fmt"
    BUILD_DIR=build
    local prebuilt_fmt_root=${PREBUILT_DIR}/fmt
    mkdir -p ${prebuilt_fmt_root}
    pushd fmt
    cmake -S . -G Ninja -DCMAKE_INSTALL_PREFIX=${prebuilt_fmt_root} -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER="clang++" -DCMAKE_C_COMPILER="clang" -DCMAKE_CXX_STANDARD=17 -DUSE_SANITIZER=address -B "$BUILD_DIR"
    _green "configure cmake done \n"
    cmake --build "$BUILD_DIR" --target install
    _green "build and install via cmake done \n"
    tree -L 4 ${prebuilt_fmt_root}
    popd
}


function _build_spd_log(){
    _purple "building spd log \n"
    git clone https://github.com/gabime/spdlog.git
    pushd spdlog && mkdir build && cd build
    cmake .. && make -j${CORES}
    popd
}


function _build_zlib(){
    _purple "building zlib \n"
    git clone --depth 1 --branch v1.3.1 https://github.com/madler/zlib
    local prebuilt_zlib_root=${PREBUILT_DIR}/zlib
    mkdir -p $prebuilt_zlib_root
    pushd zlib
    local zlib_install_dir=_install
    mkdir -p ${zlib_install_dir}
    ./configure --prefix=${zlib_install_dir}
    make -j${CORES}
    make install
    _green "\n  done build zlib  \n"
    _green "\n  zlib are binary can be found in ${zlib_install_dir} \n"
    tree -L 4 ${zlib_install_dir}
    popd
}



function _build_openssl(){
    _purple "building openssl \n"
    git clone --depth 1 --branch v3.2.1 https://github.com/openssl/openssl
    pushd ${BUILD_ROOT}/openssl
    local OPENSSL_INSTALL_DIR=${PREBUILT_DIR}/openssl
    local prebuilt_zlib_root=${PREBUILT_DIR}/zlib
    mkdir -p ${OPENSSL_INSTALL_DIR}
    ./Configure  \
    --prefix=${OPENSSL_INSTALL_DIR} \
    --openssldir=${OPENSSL_INSTALL_DIR} \
    --libdir=lib64 \
    --with-zlib-include=${prebuilt_zlib_root}/include \
    --with-zlib-lib=${prebuilt_zlib_root}/lib \
    no-shared \
    no-docs \
    zlib 

    make -j${CORES}
    make install_sw
    _green "\n  done build openssl static \n"
    _green "\n  openssl with zlib are binary can be found in ${OPENSSL_INSTALL_DIR} \n"
    tree -L 4 ${OPENSSL_INSTALL_DIR}
    popd
}


function _build_brotli(){
    _green "building brotli"
    git clone --depth 1 --branch v1.1.0 https://github.com/google/brotli
    local BROTIL_install_dir=${PREBUILT_DIR}/brotli
    mkdir -p ${brotli_INSTALL_DIR}
    pushd ${BUILD_ROOT}/brotli
    mkdir out && cd out
    cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${BROTIL_install_dir} ..
    cmake --build . --config Release --target install -j${CORES}
    tree -L 4 ${brotli_INSTALL_DIR}
    popd
}


function _prepare(){
    export CC=clang
    export CXX=clang++
    export BUILD_ROOT=`pwd`
    export PREBUILT_DIR=${BUILD_ROOT}/prebuilt

    mkdir -p ${PREBUILT_DIR}

    if [[ "$OSTYPE" == "darwin"* ]]; then
        _green "====== build script for macos start ======\n"
        export CORES=$((`sysctl -n hw.logicalcpu`+1))
    else
        _green "====== build script for linux start ======\n"
        export CORES=$((`nproc`+1))
    fi
}


function main(){

    _prepare

    _build_fmt

    _build_spd_log

    _build_zlib

    _build_openssl

    _build_brotli

}

main

