FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends zsh bundler libtbb-dev gdb sudo ninja-build git unzip vim build-essential zip unzip checkinstall python3 python3-pip zlib1g-dev wget curl tree coreutils autoconf automake libtool libidn2-0-dev pkg-config    

# [Optional] Uncomment if you want to install an additional version
#  of node using nvm
# ARG EXTRA_NODE_VERSION=18
# RUN su node -c "source /usr/local/share/nvm/nvm.sh \
#    && nvm install ${EXTRA_NODE_VERSION}"

COPY ./custom_script.sh /tmp/scripts/custom_script.sh
RUN apt-get update && bash /tmp/scripts/custom_script.sh




ENTRYPOINT [ "/usr/bin/zsh" ]
