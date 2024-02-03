#!/bin/bash

function main(){
    local current_dir=`pwd`

    export PREFIX="${current_dir}/gcc-13-build"
    export TARGET=mipsel-unknown-linux-gnu
    export WDIR=gcc13build
    sudo apt install -y build-essential
    echo "[step] : download gcc source"


    tar xvf assets/gcc-13.2.0.tar.gz -C build

    ## todo 
    # https://wiki.osdev.org/GCC_Cross-Compiler#Preparation
    ##https://www.linux-mips.org/wiki/Toolchains#Roll-your-own


    # export PATH="$PREFIX/bin:$PATH"


    # git clone git://gcc.gnu.org/git/gcc.git gcc13source
    mkdir -p ${WDIR}
    mkdir -p ${current_dir}/gcc-13-build
    cd gcc13source
    # git checkout releases/gcc-13
    # echo "[step] : checkout releases/gcc-13 , show gcc source"
    ls -alSh
    ./contrib/download_prerequisites
    cd ../gcc13build
    ls -alSh
    ./../gcc13source/configure \
    --prefix="${current_dir}/gcc-13-build" \
    --enable-languages="c,c++"  \
    --enable-shared \
    --enable-threads=posix
    make -j ${nproc}
    echo "now install begin"
    make install
    # ls -al ../gcc-13-build

}


main