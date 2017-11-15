#!/bin/zsh
# Process photolog videos

SRC_VIDEOS=videos
SCALED=scaled
# SRC_VIDEOS=test
OUTPUT=output
MONTH=09
FONT_SIZE=32
PADDING=16
FONT_SCALE=1.44
DATESTRING_W=300

# echo Cleaning contents of the output dir: $OUTPUT/*
# rm -rd $OUTPUT/*

# hasVideos=0
# for file in $SRC_VIDEOS/IMG*.mov; do;
#   creationdate=$(ffprobe $file -show_entries format_tags=com.apple.quicktime.creationdate -v quiet -print_format compact=nokey=1:p=0)
#   videoFileName=$(basename "$file")
#   fileMonth=${creationdate[6,7]}
#   if [ $fileMonth != $MONTH ]; then
#     echo Skipping $videoFileName with creation date $creationdate
#   else;
#     echo Processing $videoFileName
#     dateString=$(date -j -f "%Y-%m-%d" ${creationdate[0,10]} "+%a %d %b %Y")
#     timeString=${creationdate[12,16]}
#     hours=$(( ${timeString[0,2]} ))
#     minutes=$(( ${timeString[4,5]} ))
#     minutesFromMidnight=$(( $hours * 60 + $minutes ))
#     nineOClock=$(( 9 * 60 ))
#     minutesFromNine=$(( minutesFromMidnight - nineOClock ))
#     delta=183
#     echo -n "\tadding timestamp: ‘$dateString $timeString’..."
#     ffmpeg -i $file -y \
#       -codec:a copy \
#       -loglevel error\
#       -vf "drawtext=\
#         fontfile=/Library/Fonts/PTMono.ttc:\
#         fontcolor=white: alpha=0.7:\
#         fontsize=$FONT_SIZE:\
#         box=1: boxcolor=black@0.4: boxborderw=8:\
#         text='$dateString':\
#         x=$PADDING:\
#         y=(h - $PADDING - ascent),\
#       drawtext=\
#         fontfile=/Library/Fonts/PTMono.ttc:\
#         fontcolor=white: alpha=0.7:\
#         fontsize=$FONT_SIZE:\
#         box=1: boxcolor=black@0.4: boxborderw=8:\
#         text='${timeString[0,2]}\:${timeString[4,5]}':\
#         x=($PADDING + $DATESTRING_W + $PADDING + $(( $minutesFromNine / $delta )) * ($PADDING + text_w)):\
#         y=(h - $PADDING - ascent)"\
#       $OUTPUT/$videoFileName
#     echo ' Done.'
#     hasVideos=1
#   fi;
# done;
# if [ $hasVideos = 1 ]; then
  # ffmpeg -f concat -safe 0 -i <(for f in $OUTPUT/*.mov; do echo "file '$PWD/$f'"; done) -c copy $OUTPUT/photolog.mov -loglevel error
  # ffmpeg -i test/IMG_0163.mov -i test/IMG_0164.mov -filter_complex \
# '[0:v:0] [0:a:0] [1:v:0] [1:a:0] concat=n=2:v=1:a=1 [v] [a]' -map '[v]' -map '[a]' out.mov
  #
  #ffmpeg -i test/IMG_0167.mov -filter_complex 'concat=n=5:v=1:a=1 [v] [a]' -map '[v]' -map '[a]' out.mov 
  #
  #
  # SCALE AND BLUR STEP
  #
  echo "Scale and blur vercial videos if needed..."
  scaledCounter=0
  skippedCounter=0
  for file in $SRC_VIDEOS/IMG*.mov; do;
    videoFileName=$(basename "$file")
    eval $(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height,width $file)
    if (( $streams_stream_0_height > $streams_stream_0_width )); then
      size=${streams_stream_0_width}x${streams_stream_0_height}
      echo -n "Processing $videoFileName [$size]..."
      ffmpeg -i $file -loglevel error -y -lavfi "\
        color=black@.3:size=720x405:d=1[dark];
        [0:v]crop=720:405[blurbase];
        [blurbase]boxblur=lr='min(h,w)/20':lp=1:cr='min(cw,ch)/20':cp=1[blurred];
        [blurred][dark]overlay[darkened];
        [darkened]scale=960:720[bg];
        [0:v]scale=-1:720[fg];
        [bg][fg]overlay=(W-w)/2:(H-h)/2" \
        -crf 17 $SCALED/$videoFileName
      scaledCounter=$(( $scaledCounter + 1 ))
      echo ' done.'
    else;
      cp $file $SCALED/$videoFileName
      skippedCounter=$(( $skippedCounter + 1 ))
    fi;
  done;
  echo
  echo "$scaledCounter scaled, $skippedCounter skipped"
  # concatCommand="ffmpeg $inputList -filter_complex 'concat=$filesCounter:v=1:a=1 [v] [a]' -map '[v]' -map '[a]' photolog.mov -y"
  # # echo $concatCommand
  # eval $concatCommand
  # echo "Complete. Photolog is saved to: $OUTPUT/"


  #  Blured padding command!
  #  ffmpeg -i vertical.mov -lavfi "\
    # color=black@.3:size=720x405:d=1[dark];
    # [0:v]crop=720:405[blurbase];
    # [blurbase]boxblur=lr='min(h,w)/20':lp=1:cr='min(cw,ch)/20':cp=1[blurred];
    # [blurred][dark]overlay[darkened];
    # [darkened]scale=960:720[bg];
    # [0:v]scale=-1:720[fg];
    # [bg][fg]overlay=(W-w)/2:(H-h)/2" \
    # -crf 18 out.mov
    #
  #
  # CONCAT STEP
  #
  # echo "Concating all the videos"
  # inputList=''
  # filesCounter=0
  # for file in $OUTPUT/*.mov; do;
  #   inputList="$inputList -i $file"
  #   filesCounter=$(( $filesCounter + 1 ))
  # done;
  # concatCommand="ffmpeg $inputList -filter_complex 'concat=$filesCounter:v=1:a=1 [v] [a]' -map '[v]' -map '[a]' photolog.mov -y"
  # # echo $concatCommand
  # eval $concatCommand
  # echo "Complete. Photolog is saved to: $OUTPUT/"



# fi


#  For creating a video from many images:
#                    ffmpeg -f image2 -framerate 12 -i foo-%03d.jpeg -s WxH foo.avi
