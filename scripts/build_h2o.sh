. $(dirname "$0")/functions.sh

# Display all commands before executing them.
set -o errexit
set -o errtrace


# https://h2o.examp1e.net/install.html

function _prepare(){
    export now_dir=`pwd`
    export PREBUILT_DIR=`pwd`/prebuilt
    export build_dir=${now_dir}/build
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export CORES=$((`sysctl -n hw.logicalcpu`+1))
        export CFLAGS="-arch arm64 -isysroot $(xcrun -sdk macosx --show-sdk-path) -mmacosx-version-min=$(xcrun -sdk macosx --show-sdk-version)"
        export TARGET="arm64-apple-darwin"
    else
        export CORES=$((`nproc`+1))
        export TARGET="x86_64-linux"
    fi
    rm -rf  ${build_dir}
    mkdir -p ${build_dir}
    export prebuilt_h2o_dir=${PREBUILT_DIR}/h2o/${ARCH}
    export prebuilt_zlib_root=${PREBUILT_DIR}/zlib/${ARCH}
    export prebuilt_openssl_root=${PREBUILT_DIR}/openssl/${ARCH}
    mkdir -p ${prebuilt_h2o_dir}
    mkdir -p ${prebuilt_zlib_root}
    mkdir -p ${prebuilt_openssl_root}
    _Cyan "\n CC = ${CC}   \n"
    _Cyan "CXX = ${CXX} \n"

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
    zlib 

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
    cmake .. -DCMAKE_INSTALL_PREFIX="$prebuilt_h2o_dir" \
    -DWITH_DTRACE=off -DCMAKE_BUILD_TYPE=Release    \
    -DOPENSSL_ROOT_DIR=/path/to/openssl
    make -j${CORES}
    make install
    # local prebuilt_h2o_dir=${prebuilt_h2o_dir}
    # mkdir -p ${prebuilt_h2o_dir}
    # ./configure --prefix=${prebuilt_h2o_dir}
    # make -j${CORES}
    # make install
    # _green "\n  done build zlib  \n"
    # _green "\n  zlib are binary can be found in ${zlib_install_dir} \n"
    # tree -L 4 ${zlib_install_dir}
    # rm -rf ${build_dir}/zlib-1.3.1
    popd
}



function test_h2o(){
    cd $now_dir
    _purple "examine h2o binary \n"
    $prebuilt_h2o_dir/bin/h2o --help
    $prebuilt_h2o_dir/bin/h2o -v
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
    _build_h2o
    test_h2o
    _zip_output
}


main