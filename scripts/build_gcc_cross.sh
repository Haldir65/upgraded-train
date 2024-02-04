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
    TARGET=${GCC_HOST}
    export PREFIX="${current_dir}/gcc-13-build"
    export WDIR=gcc13build
    mkdir -p ${WDIR}
    mkdir -p ${current_dir}/gcc-13-build
    echo "[step1]: build binutils"

    mkdir build-binutils
    cd build-binutils
    ../binutils-2.42/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
    make -j 4
    make install
    cd ..
    echo "[step1]: build binutils done"

    ## todo 
    # https://wiki.osdev.org/GCC_Cross-Compiler#Preparation
    ##https://www.linux-mips.org/wiki/Toolchains#Roll-your-own


    # export PATH="$PREFIX/bin:$PATH"


    # git clone git://gcc.gnu.org/git/gcc.git gcc13source
    cd gcc13source
    # git checkout releases/gcc-13
    # echo "[step] : checkout releases/gcc-13 , show gcc source"
    ls -alSh
    ./contrib/download_prerequisites
    cd ../gcc13build
    ls -alSh
    ./../gcc13source/configure \
    --prefix="${current_dir}/gcc-13-build" \
    --host=${GCC_HOST}  \
    --target=${GCC_TARGET}  \
    --disable-nls   \
    --without-headers   \
    --enable-languages="c,c++"  \
    --enable-shared \
    --enable-threads=posix
    make -j 2
    echo "now install begin"
    make install
    # ls -al ../gcc-13-build

}


main