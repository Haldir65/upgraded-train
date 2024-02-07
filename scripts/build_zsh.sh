#!/bin/bash

ARCH=$1

CURRENT_DIR=`pwd`

##https://github.com/romkatv/zsh-bin/issues/2#issuecomment-605519737
# wget https://musl.cc/$ARCH-cross.tgz
# wget https://github.com/userdocs/qbt-musl-cross-make/releases/download/2406/$ARCH.tar.xz
# tar zxvf $$ARC.tar.xz

ROOT_DIR=$CURRENT_DIR


export SYSROOT="$ROOT_DIR"
export CC=$ROOT_DIR/$ARCH/bin/$ARCH-gcc
export CXX=$ROOT_DIR/$ARCH/bin/$ARCH-g++


export CC_PREFIX="$ARCH"
export LIB_CACHE=$ROOT_DIR/$CC_PREFIX
# export PATH="$SYSROOT/bin:$PATH"
export CFLAGS_EXTRA="-I$LIB_CACHE/include"
export LDFLAGS_EXTRA="-static  -L$LIB_CACHE/lib64 -L$LIB_CACHE/lib"



$CC --version

if [ ! -d ncurses ];then
    git clone --depth 1 https://github.com/mirror/ncurses
fi


pushd ncurses
echo "show gcc info"
$CC --version
mkdir -p $CURRENT_DIR/ncurses_install
CXXFLAGS="-fPIC" CFLAGS="-fPIC" \
./configure --prefix="$CURRENT_DIR/ncurses_install" --host=$CC_PREFIX --with-build-cc=gcc --without-shared --disable-stripping --enable-widec --without-debug
make -j ${nproc}
make install
popd


if [ ! -d zsh-5.8 ];then
    if [ ! -f zsh-5.8.tar.xz ];then
        wget https://downloads.sourceforge.net/project/zsh/zsh/5.8/zsh-5.8.tar.xz
    fi
    tar Jxvf zsh-5.8.tar.xz
fi
pushd zsh-5.8
mkdir -p $CURRENT_DIR/zsh_install
CPPFLAGS="-I$CURRENT_DIR/ncurses_install/include" \
./configure --prefix="$CURRENT_DIR/zsh_install" --host=$CC_PREFIX --enable-cflags="-I$CURRENT_DIR/ncurses_install/include $CFLAGS_EXTRA" --enable-ldflags="-L$CURRENT_DIR/ncurses_install/lib $LDFLAGS_EXTRA "
make -j ${nproc}
make install
popd

echo "you can find zsh staic binary ins \n ${CURRENT_DIR}/zsh_install/bin/zsh"


file ${CURRENT_DIR}/zsh_install/bin/zsh


mv ${CURRENT_DIR}/zsh_install ${ARCH}_dist

