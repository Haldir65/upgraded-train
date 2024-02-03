function main(){
    local current_dir=`pwd`
    sudo apt install -y build-essential
    echo "[step] : download gcc source"
    git clone git://gcc.gnu.org/git/gcc.git gcc13source
    mkdir -p gcc13build
    mkdir -p {current_dir}/gcc-13-build
    cd gcc13source
    git checkout releases/gcc-13
    echo "[step] : checkout releases/gcc-13 , show gcc source"
    ls -alSh
    ./contrib/download_prerequisites
    cd ../gcc13build
    ls -alSh
    ./../gcc13source/configure \
    --prefix="${current_dir}/gcc-13-build" \
    --enable-languages="c,c++"  \
    --host=x86_64-pc-linux-gnu
    make -j 4
    echo "now install begin"
    make install
    ls -al ../gcc

}


main