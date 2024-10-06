FROM teeks99/clang-ubuntu:20

RUN apt update && \ 
    apt install -y sudo ninja-build git unzip build-essential tree checkinstall python3 python3-pip zlib1g-dev wget curl


ARG CMAKE_VERSION=3.30.4
ARG BUILDPLATFORM=linux/amd64

ARG argname=false   #default argument when not provided in the --build-arg
RUN if [ "$argname" = "false" ] ; then echo 'false'; else echo 'true'; fi

RUN echo "BUILDPLATFORM  = ${BUILDPLATFORM}"

RUN if [ "$BUILDPLATFORM" = "linux/amd64" ]; then echo 'amd64 yes'; else echo 'amd64 yes not yes'; fi


RUN echo "TARGETPLATFORM = ${TARGETPLATFORM} \n https://nielscautaerts.xyz/making-dockerfiles-architecture-independent.html"


# download and install CMake
##  0.068 /bin/sh: 1: [: linux/arm64: unexpected operator  bash string compare with slash ?
RUN set -eux; \
    cd /home && \
    if [ "$BUILDPLATFORM" = "linux/arm64" ]; then arch=aarch64; else arch=x86_64; fi && \
    curl -o cmake.tar.gz -L https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${arch}.tar.gz && \
    tar xf cmake.tar.gz && \
    cd cmake-${CMAKE_VERSION}-linux-${arch} && \
    find . -type d -exec mkdir -p /usr/local/\{} \; && \
    find . -type f -exec mv \{} /usr/local/\{} \; && \
    cd .. && \
    rm -rf *


RUN ls -al /usr/local

RUN ls -al /usr/bin


RUN ls -al /usr/local/bin/cmake
RUN file /usr/local/bin/cmake

RUN /usr/local/bin/cmake --version

RUN cmake --version

RUN cmake --help



RUN apt autoremove && apt clean