#!/bin/bash

ARCH=$1

wget https://musl.cc/${ARCH}-cross.tgz
tar zxvf ${ARCH}-cross.tgz

ROOT_DIR=`pwd`

export CC_PREFIX="$ARCH"
export SYSROOT="$CC_PREFIX-cross"
export LIB_CACHE=$ROOT_DIR/$CC_PREFIX
export PATH="$SYSROOT/bin:$PATH"
export CFLAGS_EXTRA="-I$LIB_CACHE/include"
export LDFLAGS_EXTRA="-static -L$LIB_CACHE/lib64 -L$LIB_CACHE/lib"
export CC=$SYSROOT/bin/$ARCH-gcc

$CC --version

git clone --depth 1 https://github.com/mirror/ncurses
pushd ncurses

echo "show gcc info"
./configure --prefix="$LIB_CACHE" --host=$CC_PREFIX --with-build-cc=$CC --without-shared --disable-stripping --enable-widec --without-debug
make
make install
popd

wget https://downloads.sourceforge.net/project/zsh/zsh/5.8/zsh-5.8.tar.xz
tar Jxvf zsh-5.8.tar.xz
pushd zsh-5.8
./configure --prefix="$LIB_CACHE" --host=$CC_PREFIX --enable-cflags="$CFLAGS_EXTRA" --enable-ldflags="$LDFLAGS_EXTRA"
make
make install
popd

file $LIB_CACHE/bin/zsh # /root/aarch64-linux-musl/bin/zsh: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, with debug_info, not stripped