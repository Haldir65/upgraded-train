. $(dirname "$0")/functions.sh


readonly BUILD_ROOT=`pwd`/build/manual
readonly PREBUILT_DIR=`pwd`/prebuilt

function _build_zlib_static_and_dynamic(){
    _green "\n  starting build zlib static and dynamic\n"
    local zlib_install_dir=${PREBUILT_DIR}/zlib/${ARCH_OPENWRT}
   
    mkdir -p ${zlib_install_dir}
    wget https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz -O zlib-1.3.1.tar.gz
    tar xzvf zlib-1.3.1.tar.gz -C ${BUILD_ROOT}
    tree -L 4
    pushd ${BUILD_ROOT}/zlib-1.3
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

    make -j`nproc`
    make install
    _green "\n  done build zlib static \n"
    _green "\n  zlib are binary can be found in ${zlib_install_dir} \n"
    popd
}


function _build_openssl_static_with_zlib(){
    _green "\n  starting build zlib static \n"
    local OPENSSL_INSTALL_DIR=${PREBUILT_DIR}/openssl/${ARCH_OPENWRT}
    local prebuilt_zlib_root=${PREBUILT_DIR}/zlib/${ARCH_OPENWRT}
    mkdir -p ${BUILD_ROOT}
    mkdir -p ${OPENSSL_INSTALL_DIR}
    wget https://github.com/openssl/openssl/releases/download/openssl-3.2.0/openssl-3.2.0.tar.gz -O openssl-3.2.0.tar.gz
    tar xzvf openssl-3.2.0.tar.gz -C ${BUILD_ROOT}
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

    make -j8
    make install_sw
    _green "\n  done build openssl static \n"
    _green "\n  openssl with zlib are binary can be found in ${OPENSSL_INSTALL_DIR} \n"
    popd
}

function _prepare(){
    _green $STAGING_DIR
    local now_dir=`pwd`
    mkdir -p ${now_dir}/build
    mkdir -p ${BUILD_ROOT}
    tree -L 4 ${BUILD_ROOT}
}


function main(){
    _prepare
    _build_zlib_static_and_dynamic
    _build_openssl_static_with_zlib
}

main

