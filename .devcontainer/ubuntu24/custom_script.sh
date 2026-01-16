#!/bin/bash

SDK_URL_MIRROR="https://ftp.snt.utwente.nl/pub/software/lede/releases/19.07.1/targets/ramips/mt7621/openwrt-sdk-19.07.1-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64.tar.xz"


function install_vcpkg(){
    git clone https://github.com/microsoft/vcpkg.git
    local now_dir=`pwd`
    cd vcpkg && ./bootstrap-vcpkg.sh
    export VCPKG_ROOT=$now_dir/vcpkg
    export PATH=$VCPKG_ROOT:$PATH
    vcpkg --help
}

function install_latest_cmake(){
    wget -qO- "https://github.com/Kitware/CMake/releases/download/v3.29.2/cmake-3.29.2-linux-x86_64.tar.gz" | tar --strip-components=1 -xz -C /usr/local
    /usr/local/bin/cmake --version
    echo $PATH
    which cmake            
    cmake --version
    g++ --version
    gcc --version
    uname -a
}

function install_musl_toolchain(){
    curl -o mipsel-linux-musln32sf-cross.tgz https://musl.cc/mipsel-linux-musln32sf-cross.tgz
    mkdir -p /builder/shared-workdir/build
    tar -zxvf mipsel-linux-musln32sf-cross.tgz -C /builder/shared-workdir/build
    tree -L 4 /builder/shared-workdir/build/mipsel-linux-musln32sf-cross
    rm -rf mipsel-linux-musln32sf-cross.tgz
}


function install_musl_toolchain_qbl(){
    curl -o mipsel-linux-musl.tar.xz https://github.com/userdocs/qbt-musl-cross-make/releases/download/2417/mipsel-linux-musl.tar.xz -L
    mkdir -p /builder/shared-workdir/build
    tar -xvf mipsel-linux-musl.tar.xz -C /builder/shared-workdir/build
    tree -L 4 /builder/shared-workdir/build/mipsel-linux-musl
    rm -rf mipsel-linux-musl.tar.xz
}

function install_openwrt_mipsel(){
    mkdir -p /builder/shared-workdir/build
    curl -o openwrt-sdk-19.07.1-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64.tar.xz -L ${SDK_URL_MIRROR}
    tar xf openwrt-sdk-19.07.1-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64.tar.xz -C /builder/shared-workdir/build
    mv /builder/shared-workdir/build/openwrt-sdk-19.07.1-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64/staging_dir /builder/shared-workdir/build/staging_dir
    rm -rf /builder/shared-workdir/build/openwrt-sdk-19.07.1-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64
    ls -al /builder/shared-workdir/build/staging_dir
    tree -L 4 /builder/shared-workdir/build/staging_dir
}


function install_llvm(){
    local VERSION=18
    cd /tmp
    wget https://apt.llvm.org/llvm.sh
    chmod +x llvm.sh
    ./llvm.sh $VERSION all
    rm llvm.sh

    llvm_root_prefix=/usr/lib/llvm-

    llvm_root=${llvm_root_prefix}${VERSION}

    for bin in $llvm_root/bin/*; do
    bin=$(basename $bin)
    if [ -f /usr/bin/$bin-$VERSION ]; then
        ln -sf /usr/bin/$bin-$VERSION /usr/bin/$bin
    fi
    done
    #  https://github.com/devcontainers-community/features-llvm/blob/main/install.sh
}

function main(){
    # install_latest_cmake
    # install_vcpkg
#    install_openwrt_mipsel
#    install_musl_toolchain
#    install_musl_toolchain_qbl
#    install_llvm
   chsh -s $(which zsh)

}


main    