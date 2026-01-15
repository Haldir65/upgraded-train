#!/bin/bash
#
# This script fetches "latest" releases from GitHub for PCRE2, zlib, OpenSSL, and Nginx,
# removes common prefixes (e.g. "release-", "v") from each tag,
# downloads the tarballs, extracts them, and renames them to a consistent format.
# Finally, it statically compiles Nginx using those libraries.
#

#-----------------------------------------------------------
# 0) Minimal dependencies: If additional dependencies are needed,
#    this section can be modified to include them.
#-----------------------------------------------------------
# echo "=== Installing minimal build tools  ==="
# detect_package_manager() {
#   if command -v yum >/dev/null 2>&1; then
#     echo "yum"
#   elif command -v apt >/dev/null 2>&1; then
#     echo "apt"
#   else
#     echo ""
#   fi
# }

# install_dependencies() {
#   pkg_manager=$(detect_package_manager)

#   if [ "$pkg_manager" = "yum" ]; then
#     echo "=== Detected yum-based system ==="
#     yum install -y gcc make wget tar libtool perl-IPC-Cmd || {
#       echo "!!! Failed to install essential packages with yum."
#       exit 1
#     }
#   elif [ "$pkg_manager" = "apt" ]; then
#     echo "=== Detected apt-based system ==="
#     # Note: only test in Ubuntu 24.04.2 LTS
#     apt update && apt install -y build-essential wget tar libtool  || {
#       echo "!!! Failed to install essential packages with apt."
#       exit 1
#     }
#   else
#     echo "!!! Unsupported package manager. Please use a system with yum or apt."
#     exit 1
#   fi
# }
# install_dependencies

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
#-----------------------------------------------------------
# 1) Function: get_latest_tag_from_github
#    - Retrieves .tag_name from /releases/latest
#-----------------------------------------------------------
get_latest_tag_from_github() {
  local owner="$1"
  local repo="$2"
  local json tag_name

  json="$(curl -s "https://api.github.com/repos/${owner}/${repo}/releases/latest")"
  tag_name="$(echo "$json" | grep -oP '"tag_name":\s*"\K[^"]+')"
  echo "$tag_name"
}

#-----------------------------------------------------------
# 2) Function: clean_tag
#    - Strips "release-" or leading "v" or "pcre2" or "openssl"from a raw tag.
#-----------------------------------------------------------
clean_tag() {
  local raw="$1"
  local tmp="$raw"

  # Remove "release-" if present
  tmp="${tmp#release-}"
  # Remove leading "v" if present
  tmp="${tmp#v}"

  # Remove "pcre2-" if present
  tmp="${tmp#pcre2-}"

  # Remove "openssl-" if present
  tmp="${tmp#openssl-}"

  echo "$tmp"
}

#-----------------------------------------------------------
# 3) Function: download_and_extract
#    - Downloads an archive from GitHub refs/tags if not exists.
#    - Extracts it, detects the top-level directory, and renames
#      that directory to "<name>-<clean_tag>" for consistency.
#    - Returns the final directory name.
#-----------------------------------------------------------
download_and_extract() {
  local owner="$1"       # e.g. nginx
  local repo="$2"        # e.g. nginx
  local raw_tag="$3"     # e.g. release-1.27.3
  local clean_tag="$4"   # e.g. 1.27.3
  local name="$5"        # e.g. "nginx", "pcre2", "zlib", "openssl"

  local src_dir="$6"     # e.g. /usr/local/src
  local file="${name}-${clean_tag}.tar.gz"
  local url="https://github.com/${owner}/${repo}/archive/refs/tags/${raw_tag}.tar.gz"

  cd "$src_dir" || exit 1

  if [ ! -f "$file" ]; then
    echo "=== Downloading $file from $url ===" >&2
    curl -L "$url" -o "$file" || {
      echo "!!! Failed to download $file"
      exit 1
    }
  else
    echo "=== $file already exists, skipping download ===" >&2
  fi

  # Detect the top-level directory from the tarball
  local topdir
  topdir="$(tar tzf "$file" 2>/dev/null | head -1 | cut -d/ -f1)"
  if [ -z "$topdir" ]; then
    echo "!!! Could not determine top-level directory from $file" >&2
    return 1
  fi

  # Extract if not already
  if [ ! -d "$topdir" ]; then
    echo "=== Extracting $file ===" >&2
    tar xzf "$file" || {
      echo "!!! Failed to extract $file" >$2
      exit 1
    }
  else
    echo "=== Directory $topdir already exists, skipping extract ===" >&2
  fi

  # Now let's define a final name: e.g. "nginx-1.27.3"
  local final_dir="${name}-${clean_tag}"

  if [ "$final_dir" != "$topdir" ]; then
    echo "=== Renaming $topdir -> $final_dir ===" >&2
    rm -rf "$final_dir" 2>/dev/null || true
    mv "$topdir" "$final_dir" || {
      echo "!!! Rename failed for $topdir -> $final_dir" >&2
      return 1
    }
  fi

  echo "$final_dir"
}

#-----------------------------------------------------------
# 4) Get the "latest" tags from GitHub for each project
#    and clean them.
#-----------------------------------------------------------
PCRE2_OWNER="PCRE2Project"  ; PCRE2_REPO="pcre2"
ZLIB_OWNER="madler"         ; ZLIB_REPO="zlib"
OPENSSL_OWNER="openssl"     ; OPENSSL_REPO="openssl"
NGINX_OWNER="nginx"         ; NGINX_REPO="nginx"

pcre2_raw_tag="$(get_latest_tag_from_github "$PCRE2_OWNER" "$PCRE2_REPO")"
zlib_raw_tag="$(get_latest_tag_from_github  "$ZLIB_OWNER" "$ZLIB_REPO")"
openssl_raw_tag="$(get_latest_tag_from_github "$OPENSSL_OWNER" "$OPENSSL_REPO")"
nginx_raw_tag="$(get_latest_tag_from_github "$NGINX_OWNER" "$NGINX_REPO")"

# fallback if any empty
[ -z "$pcre2_raw_tag" ]   && pcre2_raw_tag="10.44"
[ -z "$zlib_raw_tag" ]    && zlib_raw_tag="1.3.1"
[ -z "$openssl_raw_tag" ] && openssl_raw_tag="3.6.0"
[ -z "$nginx_raw_tag" ]   && nginx_raw_tag="release-1.27.3"

echo "Raw PCRE2 tag:   $pcre2_raw_tag"
echo "Raw zlib tag:    $zlib_raw_tag"
echo "Raw OpenSSL tag: $openssl_raw_tag"
echo "Raw Nginx tag:   $nginx_raw_tag"

# Clean them
pcre2_clean_tag="$(clean_tag "$pcre2_raw_tag")"
zlib_clean_tag="$(clean_tag "$zlib_raw_tag")"
openssl_clean_tag="$(clean_tag "$openssl_raw_tag")"
nginx_clean_tag="$(clean_tag "$nginx_raw_tag")"


echo "Clean PCRE2 tag:   $pcre2_clean_tag"
echo "Clean zlib tag:    $zlib_clean_tag"
echo "Clean OpenSSL tag: $openssl_clean_tag"
echo "Clean Nginx tag:   $nginx_clean_tag"

#-----------------------------------------------------------
# 5) Prepare a location to store & build
#-----------------------------------------------------------
SRC_DIR="/usr/local/src"
NGINX_PREFIX="/usr/local/nginx"

mkdir -p "$SRC_DIR"

#-----------------------------------------------------------
# 6) Download & extract each project, renaming as <name>-<clean_tag>
#-----------------------------------------------------------
pcre2_dir="$(download_and_extract  "$PCRE2_OWNER"  "$PCRE2_REPO"  "$pcre2_raw_tag"   "$pcre2_clean_tag"   "pcre2"  "$SRC_DIR")"
zlib_dir="$(download_and_extract   "$ZLIB_OWNER"   "$ZLIB_REPO"   "$zlib_raw_tag"    "$zlib_clean_tag"    "zlib"   "$SRC_DIR")"
openssl_dir="$(download_and_extract "$OPENSSL_OWNER" "$OPENSSL_REPO" "$openssl_raw_tag" "$openssl_clean_tag" "openssl" "$SRC_DIR")"
nginx_dir="$(download_and_extract   "$NGINX_OWNER"  "$NGINX_REPO"  "$nginx_raw_tag"   "$nginx_clean_tag"   "nginx"  "$SRC_DIR")"

tree -L 4

echo "pcre2_dir:   $pcre2_dir"
tree -L 4 $pcre2_dir

echo "zlib_dir:    $zlib_dir"
tree -L 4 $zlib_dir

echo "openssl_dir: $openssl_dir"
tree -L 4 $openssl_dir

echo "nginx_dir:   $nginx_dir"
tree -L 4 $nginx_dir

#-----------------------------------------------------------
# 7) Create 'nginx' user if needed
#-----------------------------------------------------------
if ! id nginx &>/dev/null; then
  echo "=== Creating 'nginx' user ==="
  useradd -r -s /sbin/nologin nginx
fi

#-----------------------------------------------------------
# 8) Build Nginx with these libraries (static linking)
#-----------------------------------------------------------
cd "$SRC_DIR/${pcre2_dir}" && (./autogen.sh || ./configure)

cd "$SRC_DIR/$nginx_dir" || {
  echo "!!! Failed to cd into $SRC_DIR/$nginx_dir"
  exit 1
}


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
  --with-pcre="${SRC_DIR}/${pcre2_dir}" \
  --with-zlib="${SRC_DIR}/${zlib_dir}" \
  --with-openssl="${SRC_DIR}/${openssl_dir}" \
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

echo
echo "=== Done. Nginx installed to ${NGINX_PREFIX} ==="
echo "    PCRE2:   ${pcre2_clean_tag}"
echo "    zlib:    ${zlib_clean_tag}"
echo "    OpenSSL: ${openssl_clean_tag}"
echo "    Nginx:   ${nginx_clean_tag}"

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