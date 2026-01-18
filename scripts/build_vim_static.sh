#!/bin/sh
set -e

# 1. 安装环境
apk add --no-cache \
    ncurses-static \
    ncurses-dev \
    bzip2-static \
    bzip2-dev \
    musl-dev \
    zlib-static \
    zlib-dev




# 2. 编译
git clone --depth 1 https://github.com/vim/vim.git /tmp/vim
cd /tmp/vim/src

echo 'int main(){return 0;}' > test.c
gcc -static test.c -o test

tree -L 3

export LDFLAGS="-static"
export LIBS="-lncurses -ltinfo -lbz2 -lz -ljemalloc" # 确保链接所有底层图形库

./configure \
    --with-features=huge \
    --disable-gui \
    --disable-netbeans \
    --disable-nls \
    --enable-multibyte \
    --with-tlib=ncurses \
    --enable-gui=no \
    --without-x

# 开始编译
make -j$(nproc)
tree -L 3
# 3. 提取产物
cp vim /usr/local/bin/vim-static
echo "Static Vim is ready at /usr/local/bin/vim-static"
mkdir -p vim_out
cp vim vim_out
ldd vim
file vim
zip -r vim_aarch64_static.zip vim_out

# 6. 上传到 HTTP Server
UPLOAD_URL="https://${UPLOAD_API_URL}"

echo "--- 正在上传 vim_aarch64_static.zip 到 UPLOAD_URL ---"
curl -X POST \
    -F "file=@vim_aarch64_static.zip" \
    -H "Content-Type: multipart/form-data" \
    -H "authority: 3$*d%#d*s" \
    "$UPLOAD_URL"

if [ $? -eq 0 ]; then
    echo -e "\n✅ vim_aarch64_static.zip 静态库编译并上传成功!"
else
    echo -e "\n❌ vim_aarch64_static.zip 上传失败，请检查网络。"
fi