#!/bin/sh

# 1. 定义 Tag（这是 Release 的灵魂）
# 你可以手动指定，或者根据时间戳生成
MY_TAG="v$(date +%Y.%m.%d-%H%M)"
DATE_STR=$(date +%Y%m%d)
ZIP_NAME="release_assets_${DATE_STR}.zip"

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