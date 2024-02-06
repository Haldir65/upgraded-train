#!/bin/bash

# Display all commands before executing them.
set -o errexit
set -o errtrace

LLVM_VERSION=$1
LLVM_REPO_URL=${2:-https://github.com/llvm/llvm-project.git}
LLVM_CROSS="$3"

if [[ -z "$LLVM_REPO_URL" || -z "$LLVM_VERSION" ]]
then
  echo "Usage: $0 <llvm-version> <llvm-repository-url> [aarch64/riscv64]"
  echo
  echo "# Arguments"
  echo "  llvm-version         The name of a LLVM release branch without the 'release/' prefix"
  echo "  llvm-repository-url  The URL used to clone LLVM sources (default: https://github.com/llvm/llvm-project.git)"
  echo "  aarch64 / riscv64    To cross-compile an aarch64/riscv64 version of LLVM"

  exit 1
fi

# Clone the LLVM project.
if [ ! -d llvm-project ]
then
  git clone "$LLVM_REPO_URL" llvm-project
fi


echo "===== show basic info ====="
ls -al
du -sh
df -h
pwd

ROOT_DIR=`pwd`

cd llvm-project
git fetch origin
git checkout "release/$LLVM_VERSION"
git reset --hard origin/"release/$LLVM_VERSION"

# Create a directory to build the project.
mkdir -p build
# cd build

# Create a directory to receive the complete installation.
mkdir -p install

# Adjust compilation based on the OS.
CMAKE_ARGUMENTS=""

case "${OSTYPE}" in
    darwin*) ;;
    linux*) ;;
    *) ;;
esac

# Adjust cross compilation
CROSS_COMPILE=""

case "${LLVM_CROSS}" in
    aarch64*) CROSS_COMPILE="-DLLVM_HOST_TRIPLE=aarch64-linux-gnu" ;;
    riscv64*) CROSS_COMPILE="-DLLVM_HOST_TRIPLE=riscv64-linux-gnu" ;;
    mipsel*) CROSS_COMPILE="-DLLVM_HOST_TRIPLE=mipsel-linux-gnu" ;;
    *) ;;
esac

echo "===== show basic info ====="
tree -L 3
du -sh
df -h
pwd

# echo "num of processor is ${nproc}"
mkdir -p ${ROOT_DIR}/llvm-project/build

cmake -G Ninja -C cmake/caches/DistributionExample.cmake \
  -DCMAKE_INSTALL_PREFIX="${ROOT_DIR}/llvm-project/build/destdir" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_ASSERTIONS=ON  \
  -DLLVM_OPTIMIZED_TABLEGEN=ON  \
  llvm

ninja stage2-distribution
ninja stage2-install-distribution

if [ ! -d build/destdir/bin ];then
 mkdir -p build/destdir/bin
fi
mv build/destdir/usr/bin/* build/destdir/bin/

echo "===== show basic info ====="
tree -L 3
du -sh
df -h