. $(dirname "$0")/functions.sh

# Display all commands before executing them.
set -o errexit
set -o errtrace


# https://h2o.examp1e.net/install.html

function _prepare(){
    export now_dir=`pwd`
    export PREBUILT_DIR=`pwd`/prebuilt
    export build_dir=${now_dir}/build
    export CORES=$((`nproc`+1))
    export ARCH="mipsel"
    export TARGET="mipsel"
    # rm -rf  ${build_dir}
    mkdir -p ${build_dir}
    export prebuilt_h2o_dir=${PREBUILT_DIR}/h2o/${ARCH}
    export prebuilt_zlib_root=${PREBUILT_DIR}/zlib/${ARCH}
    export prebuilt_openssl_root=${PREBUILT_DIR}/openssl/${ARCH}
    export prebuilt_libuv_root=${PREBUILT_DIR}/uv/${ARCH}
    mkdir -p ${prebuilt_h2o_dir}
    mkdir -p ${prebuilt_zlib_root}
    mkdir -p ${prebuilt_libuv_root}
    mkdir -p ${prebuilt_openssl_root}

    export CC=${STAGING_DIR}/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin/mipsel-openwrt-linux-gcc
    export CXX=${STAGING_DIR}/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin/mipsel-openwrt-linux-g++
    export ROOTDIR="${STAGING_DIR}/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin"
    export AR=${ROOTDIR}/mipsel-openwrt-linux-ar
    export AS=${ROOTDIR}/mipsel-openwrt-linux-as
    export LD=${ROOTDIR}/mipsel-openwrt-linux-ld
    export RANLIB=${ROOTDIR}/mipsel-openwrt-linux-ranlib
    export NM=${ROOTDIR}/mipsel-openwrt-linux-nm
    _Cyan "\n CC = ${CC}   \n"
    _Cyan "CXX = ${CXX} \n"

}


function _build_libuv(){
    _purple "building libuv \n"
    _download_if_not_exists https://github.com/libuv/libuv/archive/refs/tags/v1.48.0.tar.gz v1.48.0.tar.gz
    mkdir -p $prebuilt_libuv_root
    tar -xzvf v1.48.0.tar.gz -C ${build_dir}
    pushd ${build_dir}/libuv-1.48.0
    mkdir -p build
    cd build && cmake .. -DCMAKE_SYSTEM_NAME=linux-musl-mipsel -DCMAKE_C_FLAGS="-I$STAGING_DIR/toolchain-mipsel_24kc_gcc-7.5.0_musl/include -D_GNU_SOURCE=1" -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX="$prebuilt_libuv_root"
    make -j${CORES}
    make install 
    popd
    _purple "building libuv done \n"
}


function _build_zlib(){
    _purple "building zlib \n"
    # git clone --depth 1 --branch v1.3.1 https://github.com/madler/zlib
    _download_if_not_exists https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz zlib-1.3.1.tar.gz
    mkdir -p $prebuilt_zlib_root
    tar -xzvf zlib-1.3.1.tar.gz -C ${build_dir}
    pushd ${build_dir}/zlib-1.3.1
    local zlib_install_dir=${prebuilt_zlib_root}
    mkdir -p ${zlib_install_dir}
    ./configure --prefix=${zlib_install_dir}
    make -j${CORES}
    make install
    _green "\n  done build zlib  \n"
    _green "\n  zlib are binary can be found in ${zlib_install_dir} \n"
    tree -L 4 ${zlib_install_dir}
    rm -rf ${build_dir}/zlib-1.3.1
    popd
}

function _build_openssl(){
    _purple "building openssl \n"
    # git clone --depth 1 --branch openssl-3.2.1 https://github.com/openssl/openssl
    _download_if_not_exists https://github.com/openssl/openssl/releases/download/openssl-3.2.1/openssl-3.2.1.tar.gz openssl-3.2.1.tar.gz
    rm -rf ${build_dir}/openssl-3.2.1
    tar -xzf openssl-3.2.1.tar.gz -C ${build_dir}
    # rm -rf openssl-3.2.1.tar.gz
    pushd ${build_dir}/openssl-3.2.1
    local OPENSSL_INSTALL_DIR=${prebuilt_openssl_root}
    mkdir -p ${OPENSSL_INSTALL_DIR}
    ./Configure  \
    --prefix=${OPENSSL_INSTALL_DIR} \
    --openssldir=${OPENSSL_INSTALL_DIR} \
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
    tree -L 4 ${OPENSSL_INSTALL_DIR}
    popd
    rm -rf ${BUILD_ROOT}/openssl-3.2.1
}


function _build_h2o(){
    _purple "building h2o \n"
    #  git clone --recurse-submodules https://github.com/h2o/h2o.git
    # git clone --depth 1 --branch v1.3.1 https://github.com/madler/zlib
    _download_if_not_exists https://github.com/h2o/h2o/archive/refs/tags/v2.2.6.tar.gz v2.2.6.tar.gz
    rm -rf ${build_dir}/h2o-2.2.6
    tar -xzvf v2.2.6.tar.gz -C ${build_dir}
    pushd ${build_dir}/h2o-2.2.6
    mkdir -p build
    cd build
    # export CPPFLAGS="-I${prebuilt_zlib_root}/include"
    # export LDFLAGS="-L${prebuilt_zlib_root}/lib"
    cmake -DCMAKE_CXX_FLAGS="-latomic" -DCMAKE_C_FLAGS="-latomic" -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_C_COMPILER=$CC -DLIBUV_LIBRARIES=$prebuilt_libuv_root/lib/libuv.a -DLIBUV_VERSION=1.48.0 -DLIBUV_INCLUDE_DIR=$prebuilt_libuv_root/include -DZLIB_USE_STATIC_LIBS=on -DZLIB_ROOT=$prebuilt_zlib_root -DOPENSSL_ROOT_DIR=$prebuilt_openssl_root -DWITH_MRUBY=off -DCMAKE_INSTALL_PREFIX="$prebuilt_h2o_dir" \
    -DWITH_DTRACE=off -DCMAKE_BUILD_TYPE=Release ..
    make -j${CORES}
    make install
    popd
}



function test_h2o(){
    cd $now_dir
    _purple "examine h2o binary \n"
    cd ${now_dir}
    _purple "show related info of curl binary \n"
    $STAGING_DIR/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin/mipsel-openwrt-linux-readelf -a prebuilt/h2o/mipsel/bin/h2o | grep "NEEDED"
}

function _zip_output(){
    cd ${now_dir}
    _purple "zip outputs \n"
    mkdir -p dist
    tar --directory ${PREBUILT_DIR} --create --xz --verbose --file dist/prebuilt.tar.xz .
    tree -L 3 dist
    _purple "zip outputs  done \n"
}




function main(){
    _prepare
    _build_zlib
    _build_openssl
    _build_libuv
    _build_h2o
    test_h2o
    _zip_output
}


main