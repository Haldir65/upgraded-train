#!/bin/bash

function main(){
    local current_dir=`pwd`
    sudo apt install -y build-essential
    echo "[step] : download gcc source"

    git clone git://gcc.gnu.org/git/gcc.git gcc13source

    mkdir -p gcc13build
    mkdir -p ${current_dir}/gcc-13-build
    cd gcc13source
    git checkout releases/gcc-13
    echo "[step] : checkout releases/gcc-13 , show gcc source"
    ls -alSh
    ./contrib/download_prerequisites
    cd ../gcc13build
    ls -alSh
    ./../gcc13source/configure \
    --prefix="${current_dir}/gcc-13-build" \
    --enable-languages="c,c++"  \
    --enable-shared \
    --enable-threads=posix
    make -j 2
    echo "now install begin"
    make install
    # ls -al ../gcc-13-build

}


main