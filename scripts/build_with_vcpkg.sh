#!/bin/bash

. $(dirname "$0")/functions.sh


# Display all commands before executing them.
set -o errexit
set -o errtrace


function main(){
    cmake --preset=default
    cmake --build build
}

main

