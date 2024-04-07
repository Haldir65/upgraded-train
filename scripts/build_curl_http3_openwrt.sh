. $(dirname "$0")/functions.sh

# Display all commands before executing them.
set -o errexit
set -o errtrace

function _download_if_not_exists(){
    local url=$1
    local FILE=$2
    if [ ! -f "$FILE" ]; then
        _blue "$FILE already exists\n"
        wget $url -O $FILE
    else
        _green "$FILE already exists\n"
    fi
}

function _prepare(){
    export now_dir=`pwd`
    # readonly BUILD_ROOT=`pwd`/build/manual
    export PREBUILT_DIR=`pwd`/prebuilt
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export CORES=$((`sysctl -n hw.logicalcpu`+1))
        # export CFLAGS="-arch arm64 -isysroot $(xcrun -sdk macosx --show-sdk-path) -mmacosx-version-min=$(xcrun -sdk macosx --show-sdk-version)"
        export lib_folder=lib
    else
        export CORES=$((`nproc`+1))
        export lib_folder=lib64
    fi
    export ARCH="mipsel"
    export TARGET="mipsel"
    export build_dir=${now_dir}/build
    export quictls_install_dir="${PREBUILT_DIR}/quictls/${ARCH}"
    export nghttp3_install_dir="${PREBUILT_DIR}/nghttp3/${ARCH}"
    export ngtcp_install_dir="${PREBUILT_DIR}/ngtcp/${ARCH}"
    export curl_http3_dir="${PREBUILT_DIR}/curlh3/${ARCH}"

    export prebuilt_nghttp2_root=${PREBUILT_DIR}/nghttp2/${ARCH}
    export prebuilt_brotli_root=${PREBUILT_DIR}/brotli/${ARCH}
    export prebuilt_zlib_root=${PREBUILT_DIR}/zlib/${ARCH}
    export prebuilt_zstd_root=${PREBUILT_DIR}/zstd/${ARCH}
    export prebuilt_psl_root=${PREBUILT_DIR}/psl/${ARCH}
    export prebuilt_c_ares_root=${PREBUILT_DIR}/c_ares/${ARCH}
    export prebuilt_libunistring_root=${PREBUILT_DIR}/libunistring/${ARCH}
    export prebuilt_icu_root=${PREBUILT_DIR}/icu/${ARCH}
    export prebuilt_idn2_root=${PREBUILT_DIR}/idn2/${ARCH}


    export CC=${STAGING_DIR}/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin/mipsel-openwrt-linux-gcc
    export CXX=${STAGING_DIR}/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin/mipsel-openwrt-linux-g++



    # rm -rf  ${build_dir}
    mkdir -p ${build_dir}


    # rm -rf  ${quictls_install_dir}
    # rm -rf  ${nghttp3_install_dir}
    # rm -rf  ${ngtcp_install_dir}
    # rm -rf  ${curl_http3_dir}
    mkdir -p ${prebuilt_libunistring_root}
    mkdir -p ${quictls_install_dir}
    mkdir -p ${nghttp3_install_dir}
    mkdir -p ${ngtcp_install_dir}
    mkdir -p ${curl_http3_dir}
    mkdir -p ${prebuilt_zstd_root}
    mkdir -p ${prebuilt_psl_root}
    mkdir -p ${prebuilt_c_ares_root}
    mkdir -p ${prebuilt_icu_root}
    mkdir -p ${prebuilt_idn2_root}


    _Cyan "\n CC = ${CC}   \n"
    _Cyan "CXX = ${CXX} \n"

}


function _build_zlib(){
    cd ${now_dir}
    _purple "building zlib \n"
    # git clone --depth 1 --branch v1.3.1 https://github.com/madler/zlib
    _download_if_not_exists https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz  zlib-1.3.1.tar.gz
    mkdir -p $prebuilt_zlib_root
    tar -xzvf zlib-1.3.1.tar.gz -C ${build_dir}
    pushd ${build_dir}/zlib-1.3.1
    local zlib_install_dir=${prebuilt_zlib_root}
    mkdir -p ${zlib_install_dir}
    CFLAGS="-fPIC" ./configure --prefix=${zlib_install_dir}
    make -j${CORES}
    make install
    _green "\n  done build zlib  \n"
    _Cyan "\n  zlib are binary can be found in ${zlib_install_dir} \n"
    tree -L 4 ${zlib_install_dir}
    rm -rf ${build_dir}/zlib-1.3.1
    popd
}


function _build_brotli(){
    cd ${now_dir}
    _green "building brotli \n"
    # git clone --depth 1 --branch v1.1.0 https://github.com/google/brotli
    _download_if_not_exists https://github.com/google/brotli/archive/refs/tags/v1.1.0.tar.gz brotli_v1.1.0.tar.gz
    mkdir -p ${prebuilt_brotli_root}
    tar -xzvf brotli_v1.1.0.tar.gz -C ${build_dir}
    pushd ${build_dir}/brotli-1.1.0
    mkdir out && cd out
    cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${prebuilt_brotli_root} ..
    cmake --build . --config Release --target install -j${CORES}
    tree -L 4 ${brotli_INSTALL_DIR}
    rm -rf ${build_dir}/brotli-1.1.0
    popd
    _Cyan "building brotli done \n"
    # rm -rf brotli_v1.1.0.tar.gz

}

function _build_quictls(){
    cd ${now_dir}
    _green "_build_quictls begin \n"
    # git clone --depth 1 -b openssl-3.1.4+quic https://github.com/quictls/openssl ${build_dir}/openssl
    _download_if_not_exists https://github.com/quictls/openssl/archive/refs/tags/opernssl-3.1.5-quic1.tar.gz openssl-opernssl-3.1.5-quic1.tar.gz
    rm -rf ${build_dir}/openssl
    rm -rf ${build_dir}/openssl-opernssl-3.1.5-quic1
    tar -xzvf openssl-opernssl-3.1.5-quic1.tar.gz -C ${build_dir}
    mv ${build_dir}/openssl-opernssl-3.1.5-quic1 ${build_dir}/openssl
    pushd ${build_dir}/openssl
    ./config enable-tls1_3 \
    --prefix=${quictls_install_dir} \
    --libdir=${lib_folder} \
    --with-zlib-include=${prebuilt_zlib_root}/include \
    --with-zlib-lib=${prebuilt_zlib_root}/lib   \
    no-shared \
    zlib \
    linux-mips32 

    make -j${CORES}
    make install_sw
    _Cyan "_build_quictls completed \n"
    rm -rf openssl-opernssl-3.1.5-quic1.tar.gz
    popd

}


function _build_zstd(){
    cd ${now_dir}
    _green "_build_zstd begin \n"
    rm -rf ${build_dir}/zstd
    _download_if_not_exists https://github.com/facebook/zstd/releases/download/v1.5.6/zstd-1.5.6.tar.gz zstd-1.5.6.tar.gz
    tar -xzvf zstd-1.5.6.tar.gz -C ${build_dir}
    mv ${build_dir}/zstd-1.5.6 ${build_dir}/zstd
    pushd ${build_dir}/zstd
    cmake -B ${build_dir}/zstdbuild -S build/cmake -G Ninja -DCMAKE_INSTALL_PREFIX="${prebuilt_zstd_root}" -DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_SHARED=OFF
    cmake --build ${build_dir}/zstdbuild --config Release --target install -j${CORES}
    _green "_build_zstd completed \n"
    rm -rf ${prebuilt_zstd_root}/share
    rm -rf zstd-1.5.6.tar.gz
    popd
}


function _build_nghttp2(){
    cd ${now_dir}
    _green "building nghttp2 \n"
    mkdir -p ${prebuilt_nghttp2_root}
    _download_if_not_exists https://github.com/nghttp2/nghttp2/releases/download/v1.59.0/nghttp2-1.59.0.tar.gz nghttp2-1.59.0.tar.gz
    tar -xzf nghttp2-1.59.0.tar.gz -C ${build_dir}
    # rm -rf nghttp2-1.59.0.tar.gz
    pushd ${build_dir}/nghttp2-1.59.0
    # export CC="gcc"
    # export CFLAGS==" -o2"
    # export CC=clang
    export LIBS="-lz -lssl"
    export CPPFLAGS="-I${quictls_install_dir}/include -I${prebuilt_zlib_root}/include"
    export CFLAGS=$CPPFLAGS
    export LDFLAGS="-L${quictls_install_dir}/${lib_folder} -L${prebuilt_zlib_root}/lib"
    _green "CPPFLAGS =${CPPFLAGS}\n"
    _green "CFLAGS =${CFLAGS}\n"
    _green "LDFLAGS =${LDFLAGS}\n"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export LDFLAGS="${LDFLAGS} -framework SystemConfiguration -framework CoreFoundation"
    fi

    ./configure --host=$TARGET \
        --enable-lib-only \
        --with-openssl=${quictls_install_dir} \
        --prefix=${prebuilt_nghttp2_root}
    make -j$CORES
    make install
    make clean
    rm -rf ${build_dir}/nghttp2-1.59.0
    rm -rf ${prebuilt_nghttp2_root}/share
    popd
    _Cyan "building nghttp2 done \n"
   

}


function _build_nghttp3(){
    cd ${now_dir}
    _green "_build_nghttp3 begin \n"
    rm -rf ${build_dir}/nghttp3-1.2.0
    _download_if_not_exists https://github.com/ngtcp2/nghttp3/releases/download/v1.2.0/nghttp3-1.2.0.tar.gz nghttp3-1.2.0.tar.gz
    tar -xzvf nghttp3-1.2.0.tar.gz -C ${build_dir}
    pushd ${build_dir}/nghttp3-1.2.0
    autoreconf -fi
    ./configure --host="${TARGET}" --prefix=${nghttp3_install_dir} --enable-lib-only 
    make -j${CORES}
    make install
    rm -rf nghttp3-1.2.0.tar.gz
    popd
    _Cyan "_build_nghttp3 completed \n"

}

function _build_c_areas(){
    cd ${now_dir}
    _green "_build_c_areas begin \n"
    local c_ares_version=1.28.1
    _download_if_not_exists https://github.com/c-ares/c-ares/releases/download/cares-1_28_1/c-ares-1.28.1.tar.gz  c-ares-1.28.1.tar.gz
    rm -rf ${build_dir}/c-ares-${c_ares_version}
     rm -rf ${build_dir}/c-ares-${c_ares_version}
    tar -xzvf c-ares-${c_ares_version}.tar.gz -C ${build_dir}
    pushd ${build_dir}/c-ares-${c_ares_version}
    ./configure --host="${TARGET}" --prefix="${prebuilt_c_ares_root}"
    make -j${CORES}
    make install
    rm -rf ${prebuilt_c_ares_root}/share
    _Cyan "_build_c_areas completed \n"
    rm -rf c-ares-${c_ares_version}.tar.gz
    popd
}


function _build_ngtcp2(){
    cd ${now_dir}
    _green "_build_ngtcp2 begin \n"
    rm -rf ${build_dir}/ngtcp2-1.4.0
    _download_if_not_exists https://github.com/ngtcp2/ngtcp2/releases/download/v1.4.0/ngtcp2-1.4.0.tar.gz ngtcp2-1.4.0.tar.gz
    tar -xzvf ngtcp2-1.4.0.tar.gz -C ${build_dir}
    pushd ${build_dir}/ngtcp2-1.4.0   
    autoreconf -fi
    ./configure --host="${TARGET}" PKG_CONFIG_PATH=${quictls_install_dir}/${lib_folder}/pkgconfig:${nghttp3_install_dir}/${lib_folder}/pkgconfig LDFLAGS="-L${prebuilt_zlib_root}/lib -L${quictls_install_dir}/${lib_folder}" --prefix=${ngtcp_install_dir} --enable-lib-only
    make -j${CORES}
    make install
    _Cyan "_build_ngtcp2 completed \n"
    rm -rf ngtcp2-1.4.0.tar.gz
    popd
}

function _build_libunistring(){
    cd ${now_dir}
    _green "_build_libunistring begin \n"
    _download_if_not_exists https://ftp.gnu.org/gnu/libunistring/libunistring-1.2.tar.gz libunistring-1.2.tar.gz
    rm -rf ${build_dir}/libunistring-1.2
    tar -xzvf libunistring-1.2.tar.gz -C ${build_dir}
    pushd ${build_dir}/libunistring-1.2
    ./configure --host=$TARGET \
    --prefix=${prebuilt_libunistring_root}
    make -j${CORES}
    make install
    _purple "_build_libunistring done \n"
    popd

}

# https://unicode-org.github.io/icu/userguide/icu4c/build.html#how-to-cross-compile-icu
function _build_icu() {
    cd ${now_dir}
    _green "_build_icu begin \n"
    _download_if_not_exists https://github.com/unicode-org/icu/releases/download/release-74-2/icu4c-74_2-src.tgz icu4c-74_2-src.tgz
    tar -xzvf icu4c-74_2-src.tgz -C ${build_dir}
    pushd ${build_dir}/icu/source
    CXXFLAGS="-std=c++11" ./configure --host=mipsel-linux-musl --build=x86_64-pc-linux-gnu  --enable-static --disable-shared --with-cross-build=${_buildA} --prefix=${prebuilt_icu_root} --with-data-packaging=static
    make -j${CORES}
    make install
    _purple "_build_icu done \n"
    popd
}


function _build_idn2(){
    cd ${now_dir}
    _green "_build_idn2 begin \n"
    _download_if_not_exists https://ftp.gnu.org/gnu/libidn/libidn2-2.3.7.tar.gz libidn2-2.3.7.tar.gz
    _purple "_build_idn2 start \n"
    tar -xzvf libidn2-2.3.7.tar.gz -C ${build_dir}
    pushd ${build_dir}/libidn2-2.3.7
    ./configure --host=mipsel-linux-musl --prefix=${prebuilt_idn2_root} --enable-shared=false --enable-static=true  && make -j${CORES} 
    make install
    _purple "_build_idn2 done \n"
    popd
}

function _build_psl(){
    cd ${now_dir}
    _green "_build_psl begin \n"
    rm -rf ${build_dir}/libpsl-0.21.5
    _download_if_not_exists https://github.com/rockdaboot/libpsl/releases/download/0.21.5/libpsl-0.21.5.tar.gz libpsl-0.21.5.tar.gz
    tar -xzvf libpsl-0.21.5.tar.gz -C ${build_dir}
    pushd ${build_dir}/libpsl-0.21.5
    PKG_CONFIG_PATH=${prebuilt_idn2_root}/lib/pkgconfig CPPFLAGS="-I${prebuilt_libunistring_root}/include -I${prebuilt_idn2_root}/include" LDFLAGS="-L${prebuilt_libunistring_root}/lib" ./configure --host=$TARGET \
    --enable-runtime=libidn2   \
    --enable-shared=false   \
    --enable-static=true   \
    --prefix=${prebuilt_psl_root}
    make -j${CORES}
    make install
    rm -rf libpsl-0.21.5.tar.gz
    _green "_build_psl completed \n"
    rm -rf ${prebuilt_libunistring_root}/share
    popd
}

function _build_curl(){
    cd ${now_dir}
    _green "_build_curl begin \n"
    _download_if_not_exists https://github.com/curl/curl/releases/download/curl-8_7_1/curl-8.7.1.tar.gz curl-8.7.1.tar.gz
    tar xzvf curl-8.7.1.tar.gz -C ${build_dir}
    # cp scripts/0001-Fix-compilation-with-disable-manual.patch ${build_dir}/curl-8.7.1/commit_38d582ff5.patch
    ## https://sourceforge.net/p/curl/bugs/1350/
    pushd ${build_dir}/curl-8.7.1
    # patch -p1 < commit_38d582ff5.patch
    rm src/tool_hugehelp.c
    # _green "prebuilt_zstd_root = ${prebuilt_zstd_root}\n"
    autoreconf -fi
    # https://github.com/curl/curl/issues/8733#issuecomment-1891847573
    # OpensSSL-3.0.3+quic, replace lib/pkgconfig ===> lib64/pkgconfig when you build ngtcp2.
    # LDFLAGS="-Wl,-rpath,${quictls_install_dir}/${lib_folder}" ./configure --with-openssl=${quictls_install_dir} --with-nghttp3=${nghttp3_install_dir} --with-ngtcp2=${ngtcp_install_dir} --prefix=${curl_http3_dir}
    mv ${ngtcp_install_dir}/lib ${ngtcp_install_dir}/lib64
    CPPFLAGS="-I${prebuilt_psl_root}/include" LIBS="-lbrotlicommon -latomic" LDFLAGS="-L${quictls_install_dir}/${lib_folder} -L${prebuilt_brotli_root}/lib -L${prebuilt_psl_root}/lib" ./configure --host=$TARGET PKG_CONFIG_PATH=${ngtcp_install_dir}/lib64/pkgconfig --with-zlib=${prebuilt_zlib_root} --with-zstd=${prebuilt_zstd_root} --with-openssl=${quictls_install_dir} --with-nghttp3=${nghttp3_install_dir} --with-ngtcp2=${ngtcp_install_dir} --with-nghttp2=${prebuilt_nghttp2_root} --with-brotli=${prebuilt_brotli_root} --enable-ares=${prebuilt_c_ares_root} --with-libidn2=${prebuilt_idn2_root} --prefix=${curl_http3_dir} \
    --with-pic \
    --disable-shared \
    --enable-pthreads \
    --disable-manual    \
    --enable-proxy \
    --enable-ipv6 \
    --enable-static \
    --disable-docs  \
    --enable-threaded-resolver \
    --enable-dict \
    --enable-unix-sockets \
    --enable-cookies    \
    --enable-http-auth  \
    --enable-doh    \
    --enable-mime 
    make -j${CORES}
    make install
    _green "_build_curl completed \n"
    rm -rf ${curl_http3_dir}/share
    rm -rf curl-8.7.1.tar.gz
    popd
}

function test_curl(){
    cd ${now_dir}
    _purple "show related info of curl binary \n"
    $STAGING_DIR/toolchain-mipsel_24kc_gcc-7.5.0_musl/bin/mipsel-openwrt-linux-readelf -a prebuilt/curlh3/${ARCH}/bin/curl | grep "NEEDED"
    # _purple "reset http_proxy since HTTP/3 is not supported over a HTTP proxy \n"
    # export http_proxy=""; export https_proxy=""
    # ${curl_http3_dir}/bin/curl --http3-only https://www.google.com -v 
    # ${curl_http3_dir}/bin/curl --http3-only https://nghttp2.org -v  
    # ${curl_http3_dir}/bin/curl -V
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
    _build_quictls
    _build_brotli
    _build_libunistring
    _build_idn2
    _build_psl
    _build_zstd
    _build_nghttp2
    _build_c_areas
    _build_nghttp3
    _build_ngtcp2
    _build_curl
    _zip_output
    test_curl
}


main