. $(dirname "$0")/functions.sh

# Display all commands before executing them.
set -o errexit
set -o errtrace


function main(){
    _green "downloading video now \n"
}


#  # yt-dlp --downloader aria2c -S "+codec:av01" https://www.youtube.com/watch?v=rkM-dTr89kQ
#           echo "began downloading ${{ github.event.inputs.video_url }} "
#           # yt-dlp -f 22 ${{ github.event.inputs.video_url }}  // based on -F outputs
#           # yt-dlp --downloader aria2c -S "+codec:av01" ${{ github.event.inputs.video_url }}
#           # yt-dlp --downloader aria2c -S "+codec:av01" https://www.youtube.com/watch?v=FCPdIvXo2rU
#           if [[ ${{ inputs.audio_only }} == 'true' ]]; then
#             echo "audio only"
#             yt-dlp -f "ba" ${{ github.event.inputs.video_url }} -o "%(title)s.f%(format_id)s.%(ext)s"
#           else
#             echo "video and audio with best format"
#             yt-dlp ${{ github.event.inputs.video_url }} -o "%(title)s.f%(format_id)s.%(ext)s"
           
#           fi

#           # WARNING: "-f best" selects the best pre-merged format which is often not the best option.
#           # To let yt-dlp download and merge the best available formats, simply do not pass any format selection.
#           # If you know what you are doing and want only the best pre-merged format, use "-f b" instead to suppress this warning
          

function _show_download_options(){
    arg_list=$1
    for arg in "${arg_list[@]}"; do
        _Cyan "[youtube] [video] [begin] [options]  $arg \n"
        yt-dlp -F ${arg}
        _orange "[youtube] [video] [end] [options]   $arg \n"
    done
}


function _download_vide_lists_audio_only(){
    arg_list=$1
    for arg in "${arg_list[@]}"; do
        _Cyan "[youtube] [audio] [begin] downloading $arg \n"
        yt-dlp -f "ba" ${arg} -o "%(title)s.f%(format_id)s.%(ext)s"
        _orange "[youtube] [audio] [end] downloading $arg \n"
    done
}


function _download_vide_lists(){
    arg_list=$1
    for arg in "${arg_list[@]}"; do
        _Cyan "[youtube] [video] [begin] downloading $arg \n"
        yt-dlp $arg -o "%(title)s.f%(format_id)s.%(ext)s"
        _orange "[youtube] [video] [end] downloading $arg \n"
    done
}


options="u:a:b:"  

CMD_SHOW_OPTIONS=2
CMD_AUDIO_ONLY=1
CMD_VIDEO_ONLY=0


# , seperated
video_url_string=""
CMD=0

while getopts "$options" opt; do
  case $opt in
    u | urls)
      args="$OPTARG"
      # 将逗号分隔的参数转换为数组
      IFS=',' read -r -a arg_list <<< "$args"
      ;;
    a | audio)
      CMD="$OPTARG"
      ;;
    \?)
      echo "无效选项: -$OPTARG" >&2
      exit 1
      ;;
  esac
done



      
if [ $CMD -eq $CMD_AUDIO_ONLY ]; then
    _download_vide_lists_audio_only $arg_list
elif [ $CMD -eq $CMD_SHOW_OPTIONS ]; then
    _show_download_options $arg_list
else
    _download_vide_lists $arg_list
fi




