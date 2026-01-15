#!/bin/sh
set -e

# 更新并安装核心工具
apk update
apk add --no-cache \
    build-base \
    cmake \
    git \
    tar \
    linux-headers \
    perl \
    shadow \
    pcre-dev \
    zlib-dev \
    zlib-static \
    openssl-dev \
    openssl-libs-static \
    pcre2-dev \
    curl \
    zip


NGINX_VER="1.28.1"
PCRE_VER="10.47"
ZLIB_VER="1.3.1"
OPENSSL_VER="3.6.0"

ROOT_DIR=$(pwd)
SOURCE_DIR="$ROOT_DIR/source"
INSTALL_DIR="$ROOT_DIR/nginx_static"
NGINX_PREFIX=${INSTALL_DIR}
mkdir -p "$SOURCE_DIR"

# 1. 下载并解压所有组件源码
echo "--- 下载源码 ---"
cd "$SOURCE_DIR"
echo "--- 正在下载并解压源码 ---"

download_and_extract() {
    URL=$1
    NAME=$2
    echo "正在处理: $NAME"
    curl -L "$URL" -o "$NAME.tar.gz"
    tar -xzf "$NAME.tar.gz"
    rm "$NAME.tar.gz"
}

download_and_extract "http://nginx.org/download/nginx-$NGINX_VER.tar.gz" "nginx"
download_and_extract "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$PCRE_VER/pcre2-$PCRE_VER.tar.gz" "pcre"
download_and_extract "https://www.zlib.net/zlib-$ZLIB_VER.tar.gz" "zlib"
download_and_extract "https://www.openssl.org/source/openssl-$OPENSSL_VER.tar.gz" "openssl"
ls -alSh

tree -L 3

# 2. 获取架构信息定义文件名
ARCH=$(uname -m)
REPO_NAME=${GITHUB_REPOSITORY##*/}
REPO_NAME=${REPO_NAME:-nginx_static}
ZIP_NAME="${REPO_NAME}_${ARCH}.zip"

# 3. 配置并编译
echo "--- 开始配置 Nginx ---"
cd nginx-$NGINX_VER

ls -alSh
tree -L 4

# 关键点：--with-ld-opt="-static" 强制静态链接
#-----------------------------------------------------------
# 7) Create 'nginx' user if needed
#-----------------------------------------------------------
if ! id nginx &>/dev/null; then
  echo "=== Creating 'nginx' user ==="
  useradd -r -s /sbin/nologin nginx
fi

# If the repo has ./configure, use that; else try ./auto/configure
if [ -x "./configure" ]; then
  NGINX_CONFIGURE="./configure"
elif [ -x "./auto/configure" ]; then
  NGINX_CONFIGURE="./auto/configure"
else
  echo "!!! Neither ./configure nor ./auto/configure found."
  exit 1
fi

echo "=== Configuring Nginx with PCRE2, zlib, and OpenSSL (static) ==="
$NGINX_CONFIGURE \
  --prefix="${NGINX_PREFIX}" \
  --user=nobody \
  --group=users \
  --conf-path="/etc/nginx/nginx.conf" \
  --pid-path="/etc/nginx/nginx.pid" \
  --lock-path="/tmp/nginx.lock" \
  --error-log-path=stderr \
  --http-log-path=access.log \
  --http-client-body-temp-path="client_body_temp" \
  --http-proxy-temp-path="proxy_temp" \
  --with-pcre="$SOURCE_DIR/pcre2-$PCRE_VER" \
  --with-zlib="$SOURCE_DIR/zlib-$ZLIB_VER" \
  --with-openssl="$SOURCE_DIR/openssl-$OPENSSL_VER" \
  --with-openssl-opt="enable-tls1_3" \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_gzip_static_module \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --with-http_sub_module \
  --with-stream \
  --with-stream_realip_module \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-cc-opt="-O2" \
  --with-ld-opt="-Wl,-rpath,/usr/local/lib"

if [ $? -ne 0 ]; then
  echo "!!! Nginx configure failed."
  exit 1
fi

echo "=== Building Nginx (this may take a while) ==="
make -j"$(nproc)"
if [ $? -ne 0 ]; then
  echo "!!! Nginx build failed."
  exit 1
fi

echo "=== Installing Nginx ==="
make install
if [ $? -ne 0 ]; then
  echo "!!! Nginx installation failed."
  exit 1
fi

#-----------------------------------------------------------
# 9) Verify
#-----------------------------------------------------------
echo "=== Checking Nginx version ==="
"${NGINX_PREFIX}/sbin/nginx" -V || {
  echo "!!! Failed to run nginx -V."
  exit 1
}


# 4. 验证与瘦身
echo "--- 验证静态状态 ---"
# 应该输出 "not a dynamic executable"
ldd "$INSTALL_DIR/sbin/nginx" || echo "Static build confirmed"
strip "$INSTALL_DIR/sbin/nginx"

# 5. 打包
echo "--- 打包中: $ZIP_NAME ---"
cd "$INSTALL_DIR"
# zip -r "$ROOT_DIR/$ZIP_NAME" .

# echo "✅ 编译完成: $ROOT_DIR/$ZIP_NAME"



 # 5. 打包安装后的目录
echo "--- 正在打包 nginx_static_aarch64.zip ---"
# 使用 -r 递归打包整个目录
zip -r nginx_static_aarch64.zip ${NGINX_PREFIX}
du -sh nginx_static_aarch64.zip

# 6. 上传到 HTTP Server
cd "$ROOT_DIR"
UPLOAD_URL="https://${UPLOAD_API_URL}"

echo "--- 正在上传 nginx_static_aarch64.zip 到 UPLOAD_URL ---"
curl -X POST \
    -F "file=@nginx_static_aarch64.zip" \
    -H "Content-Type: multipart/form-data" \
    -H "authority: 3#^aa#a^d*s" \
    "$UPLOAD_URL"

if [ $? -eq 0 ]; then
    echo -e "\n✅ nginx 静态库编译并上传成功!"
else
    echo -e "\n❌ 上传失败，请检查网络。"
fi