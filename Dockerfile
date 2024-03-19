FROM ubuntu

ARG SDK_URL="https://downloads.openwrt.org/releases/19.07.1/targets/ramips/mt7621/openwrt-sdk-19.07.1-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64.tar.xz"
ARG SDK_URL_MIRROR="https://ftp.snt.utwente.nl/pub/software/lede/releases/19.07.1/targets/ramips/mt7621/openwrt-sdk-19.07.1-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64.tar.xz"


RUN apt update

RUN apt update && \ 
    apt install -y sudo ninja-build git unzip build-essential tree checkinstall python3 python3-pip zlib1g-dev wget curl tree sudo coreutils

RUN pip install cmake

RUN cmake --version

RUN mkdir -p /home/toolchains

RUN curl -o openwrt-sdk-19.07.1-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64.tar.xz -L ${SDK_URL_MIRROR} && \
    tar xf openwrt-sdk-19.07.1-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64.tar.xz -C /home/toolchains && \
    ls -al /home/toolchains && \
    tree -L 5 /home/toolchains

ENV STAGING_DIR="/home/toolchains/openwrt-sdk-19.07.1-ramips-mt7621_gcc-7.5.0_musl.Linux-x86_64/staging_dir"

RUN echo ${STAGING_DIR}






# WORKDIR /app

# COPY entrypoint.sh .
# RUN chmod +x entrypoint.sh

# ENTRYPOINT [ "/app/entrypoint.sh" ]