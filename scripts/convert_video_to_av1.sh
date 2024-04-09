. $(dirname "$0")/functions.sh

# Display all commands before executing them.
set -o errexit
set -o errtrace

function convert_all_video_to_av1_format(){
    mkdir -p dist

    _green " creating directory now"
    # 开启nullglob选项以防止在没有匹配文件的情况下进入循环
    shopt -s nullglob
    # 创建一个空数组来存储文件名
    files=()
    # 使用for循环列举出以.webm或者.mp4为后缀的文件，并将它们添加到数组中
    for file in *.webm *.mp4 *.mkv *.m4v; do
    files+=("$file")
    done

    # 遍历数组，并输出每一个文件名
    for file in "${files[@]}"; do
        _green "found video file: $file"
        _green " processing file $file\n"
        du -sh "$file"
        # 使用FFmpeg将视频文件转码为AV1格式
        ffmpeg -i "$file" -c:v libaom-av1 -crf 30 -c:s copy -c:a copy "${file%.*}.av1.mp4"
        rm -rf $file
        _purple " done  processing file $file \n it has been deleted \n replaced with ${file%.*}.av1.mp4 \n "
        du -sh "${file%.*}.av1.mp4"
        mv "${file%.*}.av1.mp4" dist/
    done
}

function _prepare(){
    if [[ "$OSTYPE" == "darwin"* ]]; then
        _green "====== build script running on macos  ======\n"
        brew install tree
    else
        sudo apt update 
        sudo apt install tree -y
        _green "====== build script running on linux start ======\n"
    fi

}



function main(){
    _prepare
    convert_all_video_to_av1_format
    _red "all done\n"
}

main