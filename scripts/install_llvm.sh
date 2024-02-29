#!/bin/bash

# Display all commands before executing them.
set -o errexit
set -o errtrace

cmake --version


uname -a
# pip3 install --upgrade cmake
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
echo -ne '\n' | sudo ./llvm.sh 17 all
sudo rm -rf /usr/bin/clang
sudo rm -rf /usr/bin/clang++

sudo ln -s /usr/bin/clang-17 /usr/bin/clang
sudo ln -s /usr/bin/clang++-17 /usr/bin/clang++

cmake --version
clang --version