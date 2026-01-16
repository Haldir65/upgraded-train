#!/bin/bash


_green() {
    printf '\033[1;31;32m'
    printf -- "%b" "$1"
    printf '\033[0m'
}

_red() {
    printf '\033[1;31;31m'
    printf -- "%b" "$1"
    printf '\033[0m'
}

_yellow() {
    printf '\033[1;31;33m'
    printf -- "%b" "$1"
    printf '\033[0m'
}

_purple() {
    printf "\033[0;35m$1"
}

_orange() {
    printf "\033[0;33m$1"
}

_Cyan() {
    printf "\033[0;36m$1"
}

_blue() {
    printf "\033[0;34m$1"
}


function _download_if_not_exists(){
    local url=$1
    local FILE=$2
    if [ ! -f "$FILE" ]; then
        _blue "$FILE doesn't exists\n"
        # wget $url -O $FILE
        curl -L $url -o $FILE
    else
        _green "$FILE already exists\n"
    fi
}

if [[ "$OSTYPE" == "darwin"* ]]; then
    ARCH=arm64
else
    ARCH=`uname -m`
fi
_green "====== ARCH ${ARCH} ======\n"


readonly NGHTTP2_VERSION=1.63.0
readonly NGHTTP3_VERSION=1.5.0
readonly NGTCP2_VERSION=1.7.0
readonly PSL_VERSION=0.21.5
readonly c_ares_version=1.33.1


PLATFORM="undetected"

function _detect_platform(){
    OS=$(uname -s)
    ARCH=$(uname -m)

    case "$OS" in
        "Linux")
            case "$ARCH" in
                "x86_64")  PLATFORM="linux-x64" ;;
                "aarch64") PLATFORM="linux-arm64" ;;
                *)         PLATFORM="linux-unknown" ;;
            esac
            ;;
        "Darwin")
            case "$ARCH" in
                "arm64")   PLATFORM="macos-arm64" ;;
                "x86_64")  PLATFORM="macos-x64" ;;
                *)         PLATFORM="macos-unknown" ;;
            esac
            ;;
        *)
            PLATFORM="unknown"
            ;;
    esac
    _green "[Platform] ${PLATFORM}"
}

