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
    libtool \
    zlib-dev \
    zlib-static \
    openssl-dev \
    openssl-libs-static \
    pcre2-dev \
    curl \
    zip \
    jemalloc-dev \
    automake \
    autoconf

NGINX_VER="1.29.4"
PCRE_VER="10.47"
ZLIB_VER="1.3.1"
OPENSSL_VER="3.6.0"

ROOT_DIR=$(pwd)
SOURCE_DIR="$ROOT_DIR/source"
NGINX_PREFIX=/etc/nginx
INSTALL_DIR=$NGINX_PREFIX
mkdir -p "$SOURCE_DIR"
mkdir -p $NGINX_PREFIX

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


# 2. 获取架构信息定义文件名
ARCH=$(uname -m)
REPO_NAME=${GITHUB_REPOSITORY##*/}
REPO_NAME=${REPO_NAME:-nginx_static}
ZIP_NAME="${REPO_NAME}_${ARCH}.zip"


CONF_ARGS="
    --prefix="${NGINX_PREFIX}" \
     --user=nobody \
    --group=users \
    --conf-path="/etc/nginx/nginx.conf" \
    --modules-path="/etc/nginx/modules" \
    --pid-path="/etc/nginx/nginx.pid" \
    --lock-path="/tmp/nginx.lock" \
    --error-log-path=stderr \
    --http-log-path=/tmp/log/nginx/access.log \
    --http-client-body-temp-path="/etc/nginx/client_body_temp" \
    --http-proxy-temp-path="/etc/nginx/proxy_temp" \
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
    --with-stream_ssl_preread_module
"



function build_and_upload_nginx(){
    # 3. 配置并编译
  echo "--- 开始配置 Nginx ---"
  cd nginx-$NGINX_VER

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
  $NGINX_CONFIGURE $CONF_ARGS \
  --with-cc-opt="-O2" \
  --with-ld-opt="-Wl,-rpath,/usr/local/lib -ljemalloc"
    

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


  # 5. 验证与瘦身
  echo "--- 检查二进制文件 ---"
  if ldd "$INSTALL_DIR/sbin/nginx" 2>&1 | grep -q "not a dynamic executable"; then
      echo "确认成功：这是一个完全静态的二进制文件。"
  else
      echo "警告：可能存在动态依赖，尝试强制 strip。"
      strip "$INSTALL_DIR/sbin/nginx"
  fi

  # 5. 打包
  echo "--- 打包中: $ZIP_NAME ---"
  cd "$ROOT_DIR"
  cp -r $NGINX_PREFIX .

  # 5. 打包安装后的目录
  echo "--- 正在打包 nginx_static_aarch64.zip ---"
  # 使用 -r 递归打包整个目录
  zip -r nginx_${NGINX_VER}_static_aarch64.zip nginx
  du -sh nginx_${NGINX_VER}_static_aarch64.zip
  # 6. 上传到 HTTP Server
  UPLOAD_URL="https://${UPLOAD_API_URL}"

  echo "--- 正在上传 nginx_${NGINX_VER}_static_aarch64.zip 到 UPLOAD_URL ---"
  curl -X POST \
      -F "file=@nginx_${NGINX_VER}_static_aarch64.zip" \
      -H "Content-Type: multipart/form-data" \
      -H "authority: 3#^aa#a^d*s" \
      "$UPLOAD_URL"

  if [ $? -eq 0 ]; then
      echo -e "\n✅ nginx 静态库编译并上传成功!"
  else
      echo -e "\n❌ 上传失败，请检查网络。"
  fi
}


function build_nginx_brotli_module(){
  tree -L 3

  git clone --recursive https://github.com/google/ngx_brotli.git
  cd ngx_brotli
  cd ${SOURCE_DIR}/ngx_brotli/deps/brotli
  tree -L 3
  # 创建编译目录
  mkdir -p out && cd out

  # 编译 brotli 源码
  cmake -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_INSTALL_PREFIX=./installed ..
  make -j$(nproc)
  make install
  cd ${SOURCE_DIR}

    # 3. 配置并编译
  echo "--- 开始配置 Nginx ---"
  cd ${SOURCE_DIR}/nginx-$NGINX_VER

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
 $NGINX_CONFIGURE $CONF_ARGS \
    --with-cc-opt="-O2 -I${SOURCE_DIR}/ngx_brotli/deps/brotli/out/installed/include" \
    --with-ld-opt="-Wl,-rpath,/usr/local/lib -L${SOURCE_DIR}/ngx_brotli/deps/brotli/out/installed/lib -ljemalloc" \
    --add-dynamic-module=../ngx_brotli

  if [ $? -ne 0 ]; then
    echo "!!! Nginx configure failed."
    exit 1
  fi

  echo "=== Building Nginx module only ==="
  make modules
  if [ $? -ne 0 ]; then
    echo "!!! Nginx module build failed."
    exit 1
  fi

  # 5. 打包
  echo "--- 打包中: ---"
  mkdir -p $ROOT_DIR/ngx_http_brotli_module_${NGINX_VER}
  tree -L 3
  cp objs/ngx_http_brotli_filter_module.so $ROOT_DIR/ngx_http_brotli_module_${NGINX_VER}
  cp objs/ngx_http_brotli_static_module.so $ROOT_DIR/ngx_http_brotli_module_${NGINX_VER}

  cd "$ROOT_DIR"
  # 5. 打包安装后的目录
  echo "--- 正在打包 ngx_http_brotli_module_${NGINX_VER}.zip ---"
  # 使用 -r 递归打包整个目录
  zip -r ngx_http_brotli_module_aarch64_${NGINX_VER}.zip $ROOT_DIR/ngx_http_brotli_module_${NGINX_VER}
  du -sh ngx_http_brotli_module_aarch64_${NGINX_VER}.zip
  # 6. 上传到 HTTP Server
  UPLOAD_URL="https://${UPLOAD_API_URL}"

  echo "--- 正在上传 ngx_http_brotli_module_aarch64_${NGINX_VER}.zip 到 UPLOAD_URL ---"
  curl -X POST \
      -F "file=@ngx_http_brotli_module_aarch64_${NGINX_VER}.zip" \
      -H "Content-Type: multipart/form-data" \
      -H "authority: 3#^aa#a^d*s" \
      "$UPLOAD_URL"

  if [ $? -eq 0 ]; then
      echo -e "\n✅ nginx 静态库编译并上传成功!"
  else
      echo -e "\n❌ 上传失败，请检查网络。"
  fi
}

function main(){
  # build_nginx_brotli_module
  build_and_upload_nginx
}

main