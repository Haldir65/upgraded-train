#!/bin/sh
. $(dirname "$0")/version.sh

# 1. 定义 Tag（这是 Release 的灵魂）
# 你可以手动指定，或者根据时间戳生成
MY_TAG="v$(date +%Y.%m.%d-%H%M)"
DATE_STR=$(date +%Y%m%d)
ZIP_NAME="release_assets_${DATE_STR}.zip"

DATA_ASSET_URL="https://www.newsmakers.com"
## todo change url when fit


# 三个 zip 文件的下载 URL（按顺序下载到 assets/）
DOWNLOAD_URLS="${DATA_ASSET_URL}/static_assets/grpc_static_linux_x86_64.zip \
${DATA_ASSET_URL}/static_assets/grpc_static_darwin-arm64.zip \
${DATA_ASSET_URL}/static_assets/grpc_static_linux-arm64.zip"

mkdir -p assets
for url in $DOWNLOAD_URLS; do
    fname=$(basename "$url")
    if [ -f "assets/$fname" ]; then
        echo "skip existing: $fname"
        continue
    fi
    echo "Downloading $fname..."
    if command -v curl >/dev/null 2>&1; then
        curl -fSL -o "assets/$fname" "$url" || { echo "download failed: $url"; exit 1; }
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "assets/$fname" "$url" || { echo "download failed: $url"; exit 1; }
    else
        echo "neither curl nor wget available to download assets"
        exit 1
    fi
done

# 下载后校验
missing=0
for f in assets/grpc_static_linux_x86_64.zip assets/grpc_static_darwin-arm64.zip assets/grpc_static_linux-arm64.zip; do
    if [ ! -f "$f" ]; then
        echo "missing $f"
        missing=1
    fi
done
if [ "$missing" -eq 1 ]; then
    echo "lacking essential outputs"
    exit 1
fi



cd assets
mkdir -p grpc_${GRPC_VERSION}

# linux x86_64: 解压到版本目录，然后把内部 grpc 重命名为 x86_64
unzip  grpc_static_linux_x86_64.zip -d grpc_${GRPC_VERSION}
mv grpc_${GRPC_VERSION}/grpc grpc_${GRPC_VERSION}/x86_64

# darwin arm64
unzip grpc_static_darwin-arm64.zip -d grpc_${GRPC_VERSION}
mv grpc_${GRPC_VERSION}/grpc grpc_${GRPC_VERSION}/arm64

# linux arm64
unzip  grpc_static_linux-arm64.zip -d grpc_${GRPC_VERSION}
mv grpc_${GRPC_VERSION}/grpc grpc_${GRPC_VERSION}/aarch64
cd -

# 2. 准备文件
zip -rq "$ZIP_NAME" assets/

# 3. 创建 Release
# 格式：gh release create <tag> <files...> [flags]
gh release create "$MY_TAG" \
    "$ZIP_NAME" \
    --title "manual publish of $MY_TAG" \
    --notes "prebuilt static library of c++ libs" \
    --target main  # 明确指定 Tag 挂在哪个分支上

echo "已基于 Tag: $MY_TAG 完成发布"


rm -rf $ZIP_NAME