#!/bin/bash
set -eu


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


function main(){
    tree -L 3 artifact
    local file=nginx-1.28.1-aarch64-linux
    if [ ! -f "artifact/$file" ]; then
        _blue "artifact/$file doesn't exists\n"
    else
        _green "artifact/$file  exists\n"
        file artifact/$file
        sudo readelf artifact/$file -a | grep "NEEDED"
    fi
}

main


