#!/bin/bash

. $(dirname "$0")/functions.sh


# Display all commands before executing them.
set -o errexit
set -o errtrace




function _build_fmt(){
    echo "building fmt"
    wget https://github.com/fmtlib/fmt/archive/refs/tags/9.1.0.tar.gz -O fmt-9.1.0.tar.gz
    tar -xzf fmt-9.1.0.tar.gz
    rm -rf fmt-9.1.0.tar.gz
    BUILD_DIR=build
    local prebuilt_fmt_root=${PREBUILT_DIR}/fmt
    mkdir -p ${prebuilt_fmt_root}
    pushd fmt-9.1.0
    cmake -S . -G Ninja -DCMAKE_INSTALL_PREFIX=${prebuilt_fmt_root} -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER="clang++" -DCMAKE_C_COMPILER="clang" -DCMAKE_CXX_STANDARD=17 -DUSE_SANITIZER=address -B "$BUILD_DIR"
    _green "configure cmake done \n"
    cmake --build "$BUILD_DIR" --target install
    _green "build and install via cmake done \n"
    tree -L 4 ${prebuilt_fmt_root}
    popd
    rm -rf fmt-9.1.0
}


function _build_spd_log(){
    _purple "building spd log \n"
    # git clone https://github.com/gabime/spdlog.git
    wget https://github.com/gabime/spdlog/archive/refs/tags/v1.13.0.tar.gz -O spdlog-1.13.0.tar.gz
    tar -xzf spdlog-1.13.0.tar.gz
    rm -rf spdlog-1.13.0.tar.gz
    pushd spdlog-1.13.0 && mkdir build && cd build
    cmake .. && make -j${CORES}
    popd
    rm -rf spdlog-1.13.0
}


function _build_zlib(){
    _purple "building zlib \n"
    git clone --depth 1 --branch v1.3.1 https://github.com/madler/zlib
    local prebuilt_zlib_root=${PREBUILT_DIR}/zlib
    mkdir -p $prebuilt_zlib_root
    pushd zlib
    local zlib_install_dir=${prebuilt_zlib_root}
    mkdir -p ${zlib_install_dir}
    ./configure --prefix=${zlib_install_dir}
    make -j${CORES}
    make install
    _green "\n  done build zlib  \n"
    _green "\n  zlib are binary can be found in ${zlib_install_dir} \n"
    tree -L 4 ${zlib_install_dir}
    popd
    rm -rf ${BUILD_ROOT}/zlib
}



function _build_openssl(){
    _purple "building openssl \n"
    # git clone --depth 1 --branch openssl-3.2.1 https://github.com/openssl/openssl
    wget https://github.com/openssl/openssl/releases/download/openssl-3.2.1/openssl-3.2.1.tar.gz -O openssl-3.2.1.tar.gz
    tar -xzf openssl-3.2.1.tar.gz
    rm -rf openssl-3.2.1.tar.gz
    pushd ${BUILD_ROOT}/openssl-3.2.1
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
    rm -rf ${BUILD_ROOT}/openssl-3.2.1

}


function _build_brotli(){
    _green "building brotli \n"
    git clone --depth 1 --branch v1.1.0 https://github.com/google/brotli
    local brotli_INSTALL_DIR=${PREBUILT_DIR}/brotli
    mkdir -p ${brotli_INSTALL_DIR}
    pushd ${BUILD_ROOT}/brotli
    mkdir out && cd out
    cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${brotli_INSTALL_DIR} ..
    cmake --build . --config Release --target install -j${CORES}
    tree -L 4 ${brotli_INSTALL_DIR}
    popd
    rm -rf ${BUILD_ROOT}/brotli

}


function _build_nghttp2(){
    _green "building nghttp2 \n"
    local NGHTTP2_install_dir=${PREBUILT_DIR}/nghttp2
    local OPENSSL_INSTALL_DIR=${PREBUILT_DIR}/openssl
    local prebuilt_zlib_root=${PREBUILT_DIR}/zlib
    mkdir -p ${NGHTTP2_install_dir}
    wget https://github.com/nghttp2/nghttp2/releases/download/v1.59.0/nghttp2-1.59.0.tar.gz -O nghttp2-1.59.0.tar.gz
    tar -xzf nghttp2-1.59.0.tar.gz
    rm -rf nghttp2-1.59.0.tar.gz
    pushd ${BUILD_ROOT}/nghttp2-1.59.0
    # export CC="gcc"
    # export CFLAGS==" -o2"
    # export CC=clang
    export LIBS="-lz -lssl"
    export CPPFLAGS="-I${OPENSSL_INSTALL_DIR}/include -I${prebuilt_zlib_root}/include"
    export CFLAGS=$CPPFLAGS
    export LDFLAGS="-L${OPENSSL_INSTALL_DIR}/lib64 -L${prebuilt_zlib_root}/lib"
    _green "CPPFLAGS =${CPPFLAGS}\n"
    _green "CFLAGS =${CFLAGS}\n"
    _green "LDFLAGS =${LDFLAGS}\n"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export LDFLAGS="${LDFLAGS} -framework SystemConfiguration -framework CoreFoundation"
    fi

    ./configure --host=$TARGET \
        --enable-lib-only \
        --with-openssl=${OPENSSL_INSTALL_DIR} \
        --prefix=${NGHTTP2_install_dir}
    make -j$CORES
    make install
    make clean
    popd
    rm -rf ${BUILD_ROOT}/nghttp2-1.59.0

}

function _build_psl(){
    wget https://github.com/rockdaboot/libpsl/releases/download/0.21.5/libpsl-0.21.5.tar.gz -O libpsl-0.21.5.tar.gz
    tar -xzf libpsl-0.21.5.tar.gz
    rm -rf libpsl-0.21.5.tar.gz
    pushd libpsl-0.21.5
    local libpsl_install_dir=${PREBUILT_DIR}/libpsl
    mkdir -p ${libpsl_install_dir}
    ./configure --prefix=${libpsl_install_dir}  \
    --disable-runtime
    make -j$CORES
    make check
    make install
    popd 
     _green "done build libpsl = ${libpsl_install_dir} \n"
    # rm -rf libpsl-0.21.5
}



function _build_curl(){
    local OPENSSL_INSTALL_DIR=${PREBUILT_DIR}/openssl
    local prebuilt_zlib_root=${PREBUILT_DIR}/zlib
    local prebuilt_nghttp2_root=${PREBUILT_DIR}/nghttp2
    local prebuilt_brotli_root=${PREBUILT_DIR}/brotli
    local libpsl_install_dir=${PREBUILT_DIR}/libpsl


    # git clone --depth 1 --branch curl-8_6_0 https://github.com/curl/curl
    wget https://github.com/curl/curl/releases/download/curl-8_6_0/curl-8.6.0.tar.gz -O curl-8.6.0.tar.gz
    tar -xzf curl-8.6.0.tar.gz
    rm -rf curl-8.6.0.tar.gz

    local CURL_INSTALL_DIR=${PREBUILT_DIR}/curl
    mkdir -p ${CURL_INSTALL_DIR}

    pushd ${BUILD_ROOT}/curl-8.6.0

    ##When using static dependencies, the build scripts will mostly assume that you, the user, will provide all the necessary additional dependency libraries as additional arguments in the build. 
    ## With configure, by setting LIBS or LDFLAGS on the command line.
    export CPPFLAGS="-I${OPENSSL_INSTALL_DIR}/include -I${prebuilt_zlib_root}/include -I${prebuilt_brotli_root}/include -I${libpsl_install_dir}/include"
    export LDFLAGS="-L${OPENSSL_INSTALL_DIR}/lib64 -L${prebuilt_zlib_root}/lib -L${prebuilt_brotli_root}/lib -L${libpsl_install_dir}/lib"
    export LIBS="-lbrotlicommon" ##  LDFLAGS note: LDFLAGS should only be used to specify linker flags, not libraries. Use LIBS for: -lbrotlicommon
   
#  https://github.com/curl/curl/blob/master/docs/HTTP3.md 
#  For OpenSSL 3.0.0 or later builds on Linux for x86_64 architecture, substitute all occurrences of "/lib" with "/lib64"
    
    # export LDLIBS="-lbrotlicommon" ## mac上无效？

    if [[ "$OSTYPE" == "darwin"* ]]; then
        export LDFLAGS="${LDFLAGS} -framework SystemConfiguration -framework CoreFoundation"
    fi
    ## when --host is specified but --build isn't, the build system is assumed to be the same as --host
    ## Therefore, whenever you specify --host, be sure to specify --build too.
    ## 也就是说，不是交叉编译的话，不要传什么host 和 build
    ./configure --prefix=${CURL_INSTALL_DIR} \
        --with-zlib=${prebuilt_zlib_root}     \
        --with-nghttp2=${prebuilt_nghttp2_root} \
        --with-brotli=${prebuilt_brotli_root} \
        --with-openssl=${OPENSSL_INSTALL_DIR} \
        --with-pic \
        --disable-shared \
        --enable-pthreads \
        --enable-proxy \
        --enable-ipv6 \
        --enable-static \
        --enable-threaded-resolver \
        --enable-dict \
        --enable-unix-sockets \
        --enable-cookies    \
        --enable-http-auth  \
        --enable-doh    \
        --enable-mime   \
        --disable-gopher \
        --disable-ldap --disable-ldaps \
        --disable-manual \
        --disable-pop3 --disable-smtp --disable-imap \
        --disable-rtsp \
        --disable-smb \
        --disable-telnet \
        --disable-verbose  \
        --enable-debug

    _green "done build curl = ${CURL_INSTALL_DIR} \n"
    make -j$CORES
    make install
    make clean
    popd
    rm -rf ${BUILD_ROOT}/curl-8.6.0
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
        export TARGET="arm64-apple-darwin"
    else
        _green "====== build script for linux start ======\n"
        export CORES=$((`nproc`+1))
        export TARGET="x86_64-linux"
    fi
}



function _inspect_all(){
    _Cyan "show layouts openssl \n"
    tree -L 4 ${PREBUILT_DIR}/openssl
    _Cyan " show layouts fmt \n"
    tree -L 4 ${PREBUILT_DIR}/fmt
    _Cyan " show layouts brotli\n"
    tree -L 4 ${PREBUILT_DIR}/brotli
    _Cyan " show layouts zlib\n"
    tree -L 4 ${PREBUILT_DIR}/zlib
    _Cyan "\n show layouts end \n"

    _green "\n testing binary \n\n"

    file ./prebuilt/brotli/bin/brotli
    ./prebuilt/brotli/bin/brotli --version

    file ./prebuilt/libpsl/bin/psl
    ./prebuilt/libpsl/bin/psl --version

    file ./prebuilt/openssl/bin/openssl
    ./prebuilt/openssl/bin/openssl --version

}

function _zip_output(){
    mkdir -p dist 
    tar --directory ${PREBUILT_DIR} --create --xz --verbose --file dist/prebuilt.tar.xz .
}


function main(){

    _prepare

    _build_fmt

    _build_spd_log

    _build_zlib

    _build_openssl

    _build_brotli

    _build_nghttp2

    _build_psl

    _build_curl

    _zip_output

    _inspect_all

}

main

