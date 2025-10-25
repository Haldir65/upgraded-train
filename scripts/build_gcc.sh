#!/bin/bash

GCC_HOST=$1
GCC_TARGET=$2



if [[ -z "$GCC_HOST" ]]
then
  echo "misssing required arguments host"
  exit 1
fi

function main(){
    local current_dir=`pwd`
    # sudo apt install -y build-essential
    echo "[step] : download gcc source"

    # git clone git://gcc.gnu.org/git/gcc.git gcc13source

    mkdir -p gcc15build
    mkdir -p ${current_dir}/gcc-15-build
    cd gcc15source
    # git checkout releases/gcc-13
    echo "[step] : checkout releases/gcc-15 , show gcc source"
    ls -alSh
    ./contrib/download_prerequisites
    cd ../gcc15build
    ls -alSh
    ./../gcc15source/configure \
    --host=${GCC_HOST}  \
    --target=${GCC_TARGET}  \
    --prefix="${current_dir}/gcc-15-build" \
    --enable-languages="c,c++"  \
    --disable-multilib \
    --enable-shared \
    --host=${GCC_HOST}  \
    --enable-threads=posix
    make -j 2
    echo "now install begin"
    make install
    # ls -al ../gcc-13-build

}


main