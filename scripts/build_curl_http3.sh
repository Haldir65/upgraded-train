. $(dirname "$0")/functions.sh

# Display all commands before executing them.
set -o errexit
set -o errtrace

function _prepare(){
    export now_dir=`pwd`
    # readonly BUILD_ROOT=`pwd`/build/manual
    export PREBUILT_DIR=`pwd`/prebuilt
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export CORES=$((`sysctl -n hw.logicalcpu`+1))
        export CFLAGS="-arch arm64 -isysroot $(xcrun -sdk macosx --show-sdk-path) -mmacosx-version-min=$(xcrun -sdk macosx --show-sdk-version)"
        export TARGET="arm64-apple-darwin"
        export lib_folder=lib
    else
        export CORES=$((`nproc`+1))
        export TARGET="x86_64-linux"
        export lib_folder=lib64
    fi
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



    rm -rf  ${build_dir}
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


function _build_brotli(){
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
    # rm -rf brotli_v1.1.0.tar.gz

}

function _build_quictls(){
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
    zlib 

    make -j${CORES}
    make install_sw
    _green "_build_quictls completed \n"
    rm -rf openssl-opernssl-3.1.5-quic1.tar.gz
    popd

}


function _build_zstd(){
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
    _green "building nghttp2 \n"
    mkdir -p ${prebuilt_nghttp2_root}
    _download_if_not_exists https://github.com/nghttp2/nghttp2/releases/download/v$NGHTTP2_VERSION/nghttp2-$NGHTTP2_VERSION.tar.gz nghttp2-$NGHTTP2_VERSION.tar.gz
    tar -xzf nghttp2-$NGHTTP2_VERSION.tar.gz -C ${build_dir}
    rm -rf nghttp2-$NGHTTP2_VERSION.tar.gz
    pushd ${build_dir}/nghttp2-$NGHTTP2_VERSION
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
    rm -rf ${build_dir}/nghttp2-$NGHTTP2_VERSION
    rm -rf ${prebuilt_nghttp2_root}/share
    popd
   

}


function _build_nghttp3(){
    _green "_build_nghttp3 begin \n"
    rm -rf ${build_dir}/nghttp3-$NGHTTP3_VERSION
    _download_if_not_exists https://github.com/ngtcp2/nghttp3/releases/download/v$NGHTTP3_VERSION/nghttp3-$NGHTTP3_VERSION.tar.gz nghttp3-$NGHTTP3_VERSION.tar.gz
    tar -xzvf nghttp3-$NGHTTP3_VERSION.tar.gz -C ${build_dir}
    pushd ${build_dir}/nghttp3-$NGHTTP3_VERSION
    autoreconf -fi
    ./configure --prefix=${nghttp3_install_dir} --enable-lib-only
    make -j${CORES}
    make install
    _green "_build_nghttp3 completed \n"
    rm -rf nghttp3-$NGHTTP3_VERSION.tar.gz
    popd
}

function _build_c_areas(){
    _green "_build_c_areas begin \n"
    _download_if_not_exists https://github.com/c-ares/c-ares/releases/download/v${c_ares_version}/c-ares-${c_ares_version}.tar.gz c-ares-${c_ares_version}.tar.gz
    rm -rf ${build_dir}/c-ares-${c_ares_version}
     rm -rf ${build_dir}/c-ares-${c_ares_version}
    tar -xzvf c-ares-${c_ares_version}.tar.gz -C ${build_dir}
    pushd ${build_dir}/c-ares-${c_ares_version}
    ./configure --host="${TARGET}" --prefix="${prebuilt_c_ares_root}"
    make -j${CORES}
    make install
    rm -rf ${prebuilt_c_ares_root}/share
    _green "_build_c_areas completed \n"
    rm -rf c-ares-${c_ares_version}.tar.gz
    popd
}


function _build_ngtcp2(){
    _green "_build_ngtcp2 begin \n"
    rm -rf ${build_dir}/ngtcp2-$NGTCP2_VERSION
    _download_if_not_exists https://github.com/ngtcp2/ngtcp2/releases/download/v$NGTCP2_VERSION/ngtcp2-$NGTCP2_VERSION.tar.gz ngtcp2-$NGTCP2_VERSION.tar.gz
    tar -xzvf ngtcp2-$NGTCP2_VERSION.tar.gz -C ${build_dir}
    pushd ${build_dir}/ngtcp2-$NGTCP2_VERSION 
    autoreconf -fi
    ./configure PKG_CONFIG_PATH=${quictls_install_dir}/${lib_folder}/pkgconfig:${nghttp3_install_dir}/${lib_folder}/pkgconfig LDFLAGS="-L${quictls_install_dir}/${lib_folder}" --prefix=${ngtcp_install_dir} --enable-lib-only
    make -j${CORES}
    make install
    _green "_build_ngtcp2 completed \n"
    rm -rf ngtcp2-$NGTCP2_VERSION.tar.gz
    popd
}

function _build_libunistring(){
    _green "_build_libunistring begin \n"
    _download_if_not_exists https://ftp.gnu.org/gnu/libunistring/libunistring-1.2.tar.gz libunistring-1.2.tar.gz
    rm -rf ${build_dir}/libunistring-1.2
    tar -xzvf libunistring-1.2.tar.gz -C ${build_dir}
    pushd ${build_dir}/libunistring-1.2
    ./configure --prefix=${prebuilt_libunistring_root}
    make -j${CORES}
    make install
    _purple "_build_libunistring done \n"
    popd

}

function _build_psl(){
    _green "_build_psl begin \n"
    rm -rf ${build_dir}/libpsl-$PSL_VERSION
    _download_if_not_exists https://github.com/rockdaboot/libpsl/releases/download/$PSL_VERSION/libpsl-$PSL_VERSION.tar.gz libpsl-$PSL_VERSION.tar.gz
    tar -xzvf libpsl-$PSL_VERSION.tar.gz -C ${build_dir}
    pushd ${build_dir}/libpsl-$PSL_VERSION
    CPPFLAGS="-I${prebuilt_libunistring_root}/include" LDFLAGS="-L${prebuilt_libunistring_root}/lib" ./configure --prefix=${prebuilt_psl_root}
    make -j${CORES}
    make install
    rm -rf libpsl-$PSL_VERSION.tar.gz
    _green "_build_psl completed \n"
    rm -rf ${prebuilt_libunistring_root}/share
    popd
}

function _build_curl(){
    _green "_build_curl begin \n"
    local CURL_VERSION_NUMERIC=8.9.1
    _download_if_not_exists https://github.com/curl/curl/releases/download/curl-8_9_1/curl-$CURL_VERSION_NUMERIC.tar.gz curl-$CURL_VERSION_NUMERIC.tar.gz
    tar xzvf curl-$CURL_VERSION_NUMERIC.tar.gz -C ${build_dir}
    # cp scripts/0001-Fix-compilation-with-disable-manual.patch ${build_dir}/curl-8.7.1/commit_38d582ff5.patch
    ## https://sourceforge.net/p/curl/bugs/1350/
    pushd ${build_dir}/curl-$CURL_VERSION_NUMERIC
    # patch -p1 < commit_38d582ff5.patch
    rm src/tool_hugehelp.c
    # _green "prebuilt_zstd_root = ${prebuilt_zstd_root}\n"
    autoreconf -fi
    # LDFLAGS="-Wl,-rpath,${quictls_install_dir}/${lib_folder}" ./configure --with-openssl=${quictls_install_dir} --with-nghttp3=${nghttp3_install_dir} --with-ngtcp2=${ngtcp_install_dir} --prefix=${curl_http3_dir}
    CPPFLAGS="-I${prebuilt_psl_root}/include" LIBS="-lbrotlicommon" LDFLAGS="-Wl,-rpath,${quictls_install_dir}/${lib_folder} -L${prebuilt_brotli_root}/lib -L${prebuilt_psl_root}/lib" ./configure --prefix=${curl_http3_dir} \
    --with-zlib=$prebuilt_zlib_root \
    --with-libps=$prebuilt_psl_root \
    --with-zstd=$prebuilt_zstd_root \
    --with-openssl=$quictls_install_dir \
    --with-nghttp3=$nghttp3_install_dir \
    --with-ngtcp2=$ngtcp_install_dir \
    --with-nghttp2=$prebuilt_nghttp2_root \
    --with-brotli=$prebuilt_brotli_root \
    --enable-ares=$prebuilt_c_ares_root \
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
    rm -rf curl-$CURL_VERSION_NUMERIC.tar.gz
    popd
}

function test_curl(){
    cd $now_dir
    _purple "reset http_proxy since HTTP/3 is not supported over a HTTP proxy \n"
    export http_proxy=""; export https_proxy=""
    _purple "try grab binary using our curl \n"
    ${curl_http3_dir}/bin/curl -L https://github.com/fmtlib/fmt/archive/refs/tags/9.1.0.tar.gz -o fmt-9.1.0.tar.gz -v
    tar -xzf fmt-9.1.0.tar.gz
    tree -L 4 fmt-9.1.0
    local BUILD_DIR=build
    mkdir -p fmt_build
    pushd fmt-9.1.0
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export CXX="clang++"
        export CC="clang"
    else
        export CXX="g++"
        export CC="gcc"
    fi
     _orange "CC = ${CC}\n"
    _orange "CXX = ${CXX}\n"
    cmake -S . -G Ninja -DCMAKE_INSTALL_PREFIX=$now_dir/fmt_build -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER="${CXX}" -DCMAKE_C_COMPILER="${CC}" -DCMAKE_CXX_STANDARD=17 -DUSE_SANITIZER=address -B "$BUILD_DIR"
    _green "configure cmake done \n"
    cmake --build "$BUILD_DIR" --target install
    _green "build and install via cmake done \n"
    popd
    rm -rf fmt-9.1.0

    ${curl_http3_dir}/bin/curl --http3-only https://www.google.com -v 
    ${curl_http3_dir}/bin/curl --http3-only https://nghttp2.org -v  
    ${curl_http3_dir}/bin/curl -V
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