. $(dirname "$0")/functions.sh


# Display all commands before executing them.
set -o errexit
set -o errtrace

readonly BUILD_ROOT=`pwd`/build/manual
readonly PREBUILT_DIR=`pwd`/prebuilt


function _prepare(){
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export CORES=$((`sysctl -n hw.logicalcpu`+1))
        export CFLAGS="-arch arm64 -isysroot $(xcrun -sdk macosx --show-sdk-path)"
        export TARGET="arm64-apple-darwin"
    else
        export CORES=$((`nproc`+1))
        export TARGET="x86_64-linux"
    fi
    _green $STAGING_DIR
    local now_dir=`pwd`
    mkdir -p ${now_dir}/build
    mkdir -p ${BUILD_ROOT}
    tree -L 4 ${BUILD_ROOT}
}


function _build_zlib_static_and_dynamic(){
    _green "\n  starting build zlib static and dynamic\n"
    local zlib_install_dir=${PREBUILT_DIR}/zlib
   
    mkdir -p ${zlib_install_dir}
    wget https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz -O zlib-1.3.1.tar.gz
    tar xzvf zlib-1.3.1.tar.gz -C ${BUILD_ROOT}
    rm -rf zlib-1.3.1.tar.gz
    tree -L 4
    pushd ${BUILD_ROOT}/zlib-1.3.1
    # CXXLAGS="-fPIC"  \
    ## # configure script for zlib.
    #
    # Normally configure builds both a static and a shared library.
    # If you want to build just a static library, use: ./configure --static

    ## 这里最后加上 CFLAGS="-fPIC" \才搞定
    ## 教训 ： 不需要export ，但是要加一个斜杠

    CC=${STAGING_DIR}/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin/mipsel-openwrt-linux-gcc \
    CFLAGS="-fPIC" \
    ./configure --prefix=${zlib_install_dir}

    make -j${CORES}
    make install
    _green "\n  done build zlib static \n"
    _green "\n  zlib are binary can be found in ${zlib_install_dir} \n"
    popd
}


function _build_openssl_static_with_zlib(){
    _green "\n  starting build zlib static \n"
    local OPENSSL_INSTALL_DIR=${PREBUILT_DIR}/openssl
    local prebuilt_zlib_root=${PREBUILT_DIR}/zlib
    mkdir -p ${BUILD_ROOT}
    mkdir -p ${OPENSSL_INSTALL_DIR}
    wget https://github.com/openssl/openssl/releases/download/openssl-3.2.0/openssl-3.2.0.tar.gz -O openssl-3.2.0.tar.gz
    tar xzvf openssl-3.2.0.tar.gz -C ${BUILD_ROOT}
    rm -rf openssl-3.2.0.tar.gz
    tree -L 4
    pushd ${BUILD_ROOT}/openssl-3.2.0
    ./Configure  \
    --cross-compile-prefix=${STAGING_DIR}/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin/mipsel-openwrt-linux- \
    --openssldir=${OPENSSL_INSTALL_DIR} \
    --prefix=${OPENSSL_INSTALL_DIR} \
    --libdir=lib \
    --with-zlib-include=${prebuilt_zlib_root}/include \
    --with-zlib-lib=${prebuilt_zlib_root}/lib \
    no-shared \
    no-docs \
    zlib \
    linux-mips32

    make -j${CORES}
    make install_sw
    _green "\n  done build openssl static \n"
    _green "\n  openssl with zlib are binary can be found in ${OPENSSL_INSTALL_DIR} \n"
    popd
    _Cyan "====== complete build openssl for openwrt ======\n"

}


function _build_brotil_static() {
    _green "====== build brotil for openwrt start ======\n"
    local BROTIL_VERNUM="1.1.0"
    local BROTIL_install_dir=${PREBUILT_DIR}/brotli
    local BROTIL_build_root=${BUILD_ROOT}/brotli-${BROTIL_VERNUM}

    rm -rf ${BROTIL_build_root}
    mkdir -p ${BUILD_ROOT}
    mkdir -p ${BROTIL_install_dir}
    wget https://github.com/google/brotli/archive/refs/tags/v${BROTIL_VERNUM}.tar.gz -O brotli-${BROTIL_VERNUM}.tar.gz
    tar xzvf brotli-${BROTIL_VERNUM}.tar.gz -C ${BUILD_ROOT}
    rm -rf brotli-${BROTIL_VERNUM}.tar.gz
    local now_path=`pwd`
    pushd ${BROTIL_build_root}

    # export CC="gcc"
    # export CFLAGS==" -o2"
    mkdir out && cd out
    cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${BROTIL_install_dir} -DCMAKE_TOOLCHAIN_FILE=${now_path}/cmake/mipsel-linux-gcc.cmake ..
    cmake --build . --config Release --target install -j${CORES}
    popd 
    _Cyan "====== complete build brotli-${BROTIL_VERNUM} for openwrt ======\n"

}


function _build_nghttp2_static_openwrt() {
    _green "====== build nghttp2 for openwrt start ======\n"
    local NGHTTP2_install_dir=${PREBUILT_DIR}/nghttp2
    local OPENSSL_INSTALL_DIR=${PREBUILT_DIR}/openssl
    local prebuilt_zlib_root=${PREBUILT_DIR}/zlib
    rm -rf ${BUILD_ROOT}
    mkdir -p ${BUILD_ROOT}
    mkdir -p ${NGHTTP2_install_dir}
    wget https://github.com/nghttp2/nghttp2/releases/download/v1.59.0/nghttp2-1.59.0.tar.gz -O nghttp2-1.59.0.tar.gz
    tar xzvf nghttp2-1.59.0.tar.gz -C ${BUILD_ROOT}
    rm -rf nghttp2-1.59.0.tar.gz
    pushd ${BUILD_ROOT}/nghttp2-1.59.0

    # export CFLAGS=="-I${OPENSSL_INSTALL_DIR}/include -I${prebuilt_zlib_root}/include  -lz -lssl"
    export LIBS="-lz -lssl"
    export CPPFLAGS="-fPIC -I${OPENSSL_INSTALL_DIR}/include -I${prebuilt_zlib_root}/include"
    export LDFLAGS="-L${OPENSSL_INSTALL_DIR}/lib -L${prebuilt_zlib_root}/lib "
    # if [[ "$OSTYPE" == "darwin"* ]]; then
    #     export LDFLAGS="${LDFLAGS} -framework SystemConfiguration -framework CoreFoundation"
    # fi
    CC=${STAGING_DIR}/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin/mipsel-openwrt-linux-gcc \
    ./configure --host=mipsel-linux \
        --disable-shared \
        --enable-lib-only \
        --with-openssl=${OPENSSL_INSTALL_DIR} \
        --prefix=${NGHTTP2_install_dir}



    make -j$CORES
    make install
    # make clean
    popd
    _Cyan "====== complete build nghttp2 for openwrt ======\n"
}



## https://curl.se/docs/install.html
function _build_curl_static() {
    export TARGET="mipsel-linux-musl"
    export BUNDLE_CA_PATH=`pwd`/assets/cacert-2024-03-11.pem
    local CURL_INSTALL_DIR=${PREBUILT_DIR}/curl
    local OPENSSL_INSTALL_DIR=${PREBUILT_DIR}/openssl
    local prebuilt_nghttp2_root=${PREBUILT_DIR}/nghttp2
    local prebuilt_zlib_root=${PREBUILT_DIR}/zlib
    local prebuilt_brotli_root=${PREBUILT_DIR}/brotli
    _green ${BUILD_ROOT}
    rm -rf ${BUILD_ROOT}
    mkdir -p ${BUILD_ROOT}
    mkdir -p ${CURL_INSTALL_DIR}
    wget https://github.com/curl/curl/releases/download/curl-8_5_0/curl-8.5.0.tar.gz -O curl-8.5.0.tar.gz
    tar xzvf curl-8.5.0.tar.gz -C ${BUILD_ROOT}
    rm -rf curl-8.5.0.tar.gz
    export ROOTDIR="${STAGING_DIR}/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin"
    pushd ${BUILD_ROOT}/curl-8.5.0

    export CPPFLAGS="-I${OPENSSL_INSTALL_DIR}/include -I${prebuilt_zlib_root}/include"
    export LDFLAGS="-L${OPENSSL_INSTALL_DIR}/lib -L${prebuilt_zlib_root}/lib -L${prebuilt_brotli_root}/lib"
    ##You must explicitly specify the cross tools which you want to use
    ## to build the program. This is done by setting environment variables before running the ‘configure’ script. You must normally set at least the environment variables ‘CC’, ‘AR’, and ‘RANLIB’ to the cross tools which you want to use to build. For some programs, you must set additional cross tools as well, such as ‘AS’, ‘LD’, or ‘NM’. You would set these environment variables to the build cross host tools which you are going to use.

    export CC=${ROOTDIR}/mipsel-openwrt-linux-gcc
    export CXX=${ROOTDIR}/mipsel-openwrt-linux-g++
    export AR=${ROOTDIR}/mipsel-openwrt-linux-ar
    export AS=${ROOTDIR}/mipsel-openwrt-linux-as
    export LD=${ROOTDIR}/mipsel-openwrt-linux-ld
    export RANLIB=${ROOTDIR}/mipsel-openwrt-linux-ranlib
    export NM=${ROOTDIR}/mipsel-openwrt-linux-nm
    # export LDLIBS="-lbrotlicommon"
    export LIBS="-lssl -lbrotlicommon -lcrypto -latomic" ## 加上latomic 才可以，垃圾gcc 7
    # export LDLIBS="-lbrotlicommon" 无用
    # CPPFLAGS="-I${OPENSSL_INSTALL_DIR}/include"
    # LDFLAGS="-L${OPENSSL_INSTALL_DIR}/lib" \
    ## https://www.sourceware.org/autobook/autobook/autobook_143.html
    ## Therefore, by convention, if the ‘--host’ option is used, 
    ## but the ‘--build’ option is not used, then the build system defaults to the host system
    ## 简单讲，如果是交叉编译吗，如果传了host，必须传build ,如果不传build,就用 当前编译的机器作为Build
    ## tldr, 交叉编译必须传build和host
    build=`./config.guess`
    _green "build is ${build}\n"
    ./configure --host=$TARGET \
        --build=${build}    \
        --prefix=${CURL_INSTALL_DIR} \
        --with-ca-path=/etc/ssl/certs \
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
    _green "\nCPPFLAGS = \n${CPPFLAGS}\n"
    _green "\nLDFLAGS = \n${LDFLAGS}\n"
    _green "\nprebuilt_brotli_root = \n${prebuilt_brotli_root}\n"


    make -j${CORES}
    make install
    make clean
    popd
    _Cyan "====== complete build curl for openwrt ======\n"
}


function main(){
    _prepare
    _build_zlib_static_and_dynamic
    _build_openssl_static_with_zlib
    _build_brotil_static
    _build_nghttp2_static_openwrt
    _build_curl_static
}

main

