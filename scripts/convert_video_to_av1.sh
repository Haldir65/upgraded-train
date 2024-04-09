. $(dirname "$0")/functions.sh

# Display all commands before executing them.
set -o errexit
set -o errtrace

function convert_all_video_to_av1_format(){
    mkdir -p dist
    _green " creating directory now"
    # 遍历当前目录下的所有视频文件
    for file in *.mp4 *.mkv *.webm *.avi *.mov *.flv *.wmv *.ogg *.ogv *.qt *.m4v *.mpg *.mpeg *.3gp *.asf *.rm *.swf
    do
        _green " processing file $file\n"
        du -sh $file
        # 使用FFmpeg将视频文件转码为AV1格式
        ffmpeg -i "$file" -c:v libaom-av1 -crf 30 -c:s copy -c:a copy "${file%.*}.av1.mp4"
        rm -rf $file
        _purple " done  processing file $file \n it has been deleted \n replaced with ${file%.*}.av1.mp4 \n "
        du -sh "${file%.*}.av1.mp4"
        mv "${file%.*}.av1.mp4" dist/
    done
}



function main(){
    convert_all_video_to_av1_format
    _red "all done\n"
}

main