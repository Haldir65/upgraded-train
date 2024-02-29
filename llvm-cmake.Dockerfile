FROM teeks99/clang-ubuntu:17

RUN apt update && \ 
    apt install -y sudo ninja-build git unzip build-essential tree checkinstall python3 python3-pip zlib1g-dev wget curl


ARG CMAKE_VERSION=3.28.3
ARG BUILDPLATFORM

# download and install CMake
RUN cd /home && \
    if [ "$BUILDPLATFORM" == "linux/arm64" ]; then arch=aarch64; else arch=x86_64; fi && \
    curl -o cmake.tar.gz -L https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${arch}.tar.gz && \
    tar xf cmake.tar.gz && \
    cd cmake-${CMAKE_VERSION}-linux-${arch} && \
    find . -type d -exec mkdir -p /usr/local/\{} \; && \
    find . -type f -exec mv \{} /usr/local/\{} \; && \
    cd .. && \
    rm -rf *

RUN apt autoremove && apt clean