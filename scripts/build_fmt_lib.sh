#!/bin/bash

# Display all commands before executing them.
set -o errexit
set -o errtrace

BUILD_DIR=build

clang --version
export PATH=$BUILD_DIR:$PATH
clang --version

cmake --version

cmake -S fmt -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_COMPILER="clang++" -DCMAKE_C_COMPILER="clang" -DUSE_SANITIZER=address -B "$BUILD_DIR"
cmake --build "$BUILD_DIR" -j