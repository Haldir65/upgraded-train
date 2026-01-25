# 遇到错误停止
$ErrorActionPreference = "Stop"

# --- 配置 ---
$RepoUrl = "https://github.com/rockdaboot/libpsl.git"
$PslDataUrl = "https://publicsuffix.org/list/public_suffix_list.dat"
$BuildDir = "build_msvc"
$InstallDir = "libpsl_dist"
$ZipName = "libpsl_msvc_x64_static.zip"

Write-Host "=== 开始克隆 libpsl 源码 ===" -ForegroundColor Cyan
if (-not (Test-Path "libpsl")) {
    git clone $RepoUrl libpsl
}
Set-Location libpsl

# 初始化并更新子模块 (如 m4 等)
git submodule update --init --recursive


# --- 下载最新的公共后缀列表 ---
$ListDir = "list"
if (-not (Test-Path $ListDir)) {
    New-Item -ItemType Directory -Path $ListDir
}
Write-Host "=== 下载最新的 public_suffix_list.dat ===" -ForegroundColor Cyan
Invoke-WebRequest -Uri $PslDataUrl -OutFile "$ListDir\public_suffix_list.dat"

# --- 准备构建目录 ---
if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }
if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
New-Item -ItemType Directory -Path $BuildDir
New-Item -ItemType Directory -Path $InstallDir

Write-Host "=== 配置工程 (MSVC Static /MT) ===" -ForegroundColor Cyan
# 明确指定编译器为 cl，确保生成 .lib 而不是 .a
$env:CC = "cl"
$env:CXX = "cl"

# --prefix 必须是绝对路径
$PrefixPath = Join-Path (Get-Location) $InstallDir

meson setup $BuildDir `
    --buildtype=release `
    --default-library=static `
    --prefix="$PrefixPath" `
    -Db_vscrt=mt `
    -Dtests=false `
    -Druntime=auto `
    --wipe

Write-Host "=== 编译与安装 ===" -ForegroundColor Cyan
meson compile -C $BuildDir
meson install -C $BuildDir

# --- 打包产物 ---
Write-Host "=== 正在整理并压缩产物 ===" -ForegroundColor Cyan
# 移除不必要的文件夹
$PkgConfigPath = Join-Path $PrefixPath "lib/pkgconfig"
if (Test-Path $PkgConfigPath) { Remove-Item -Recurse -Force $PkgConfigPath }

# 使用 PowerShell 原生压缩命令，生成标准的 .zip
$ZipPath = Join-Path ".." $ZipName
if (Test-Path $ZipPath) { Remove-Item $ZipPath }
Compress-Archive -Path "$InstallDir\*" -DestinationPath $ZipPath

Write-Host "=== 成功完成！产物位于: $ZipName ===" -ForegroundColor Green
Set-Location ..