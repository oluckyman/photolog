#!/bin/zsh
# Process photolog videos

MONTH=09
SRC_VIDEOS=videos

OUTPUT=output
FILTERED=$OUTPUT/filtered
SCALED=$OUTPUT/scaled
STAMPED=$OUTPUT/stamped
RESULT=$OUTPUT/photolog_$MONTH.mov

FONT_SIZE=32
PADDING=16
FONT_SCALE=1.44
DATESTRING_W=300

#
# INIT OUTPUT DIR
#
rm -rd $OUTPUT/*


#
# FILTER BY MONTH
#
echo "Filtering by month $MONTH."
mkdir -p $FILTERED
processedCounter=0
skippedCounter=0
for file in $SRC_VIDEOS/*.mov; do;
  creationdate=$(ffprobe $file -show_entries format_tags=com.apple.quicktime.creationdate -v quiet -print_format compact=nokey=1:p=0)
  videoFileName=$(basename "$file")
  fileMonth=${creationdate[6,7]}
  dateString=${creationdate[0,10]}
  timeString=${creationdate[12,16]}
  if [ $fileMonth != $MONTH ]; then
    echo "\tSkipping $videoFileName @ $dateString $timeString"
    skippedCounter=$(( $skippedCounter + 1 ))
  else;
    cp $file "$FILTERED/${dateString}T${timeString/\:/_} $videoFileName"
    processedCounter=$(( $processedCounter + 1 ))
  fi;
done;
echo "\n$processedCounter processed, $skippedCounter skipped\n\n"
SRC_VIDEOS=$FILTERED


#
# SCALE AND BLUR STEP
#
echo "Rescaling vercial videos if needed."
processedCounter=0
skippedCounter=0
mkdir -p $SCALED
for file in $SRC_VIDEOS/*.mov; do;
  videoFileName=$(basename "$file")
  eval $(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height,width $file)
  if (( $streams_stream_0_height > $streams_stream_0_width )); then
    size=${streams_stream_0_width}x${streams_stream_0_height}
    echo -n "\tProcessing $videoFileName [$size]..."
    ffmpeg -i $file -loglevel error -y -lavfi "\
      color=black@.3:size=720x405:d=1[dark];
      [0:v]crop=720:405[blurbase];
      [blurbase]boxblur=lr='min(h,w)/20':lp=1:cr='min(cw,ch)/20':cp=1[blurred];
      [blurred][dark]overlay[darkened];
      [darkened]scale=960:720[bg];
      [0:v]scale=-1:720[fg];
      [bg][fg]overlay=(W-w)/2:(H-h)/2" \
      -crf 17 $SCALED/$videoFileName
    processedCounter=$(( $processedCounter + 1 ))
    echo ' done.'
  else;
    cp $file $SCALED/$videoFileName
    skippedCounter=$(( $skippedCounter + 1 ))
  fi;
done;
echo "\n$processedCounter processed, $skippedCounter skipped\n\n"
SRC_VIDEOS=$SCALED


#
# TIMESTAMPS STEP
#
echo "Adding timestamps to the videos."
mkdir -p $STAMPED
processedCounter=0
for file in $SRC_VIDEOS/*.mov; do;
  videoFileName=$(basename "$file")
  echo -n "\tProcessing ${videoFileName[18,999]}..."
  dateString=${videoFileName[0,10]}
  timeString=${videoFileName[12,16]}
  hours=$(( ${timeString[0,2]} ))
  minutes=$(( ${timeString[4,5]} ))
  minutesFromMidnight=$(( $hours * 60 + $minutes ))
  nineOClock=$(( 9 * 60 ))
  minutesFromNine=$(( minutesFromMidnight - nineOClock ))
  delta=183
  echo -n " Adding timestamp: ‘$dateString $timeString’..."
  ffmpeg -i $file -y \
    -codec:a copy \
    -loglevel error\
    -vf "drawtext=\
    fontfile=/Library/Fonts/PTMono.ttc:\
    fontcolor=white: alpha=0.7:\
    fontsize=$FONT_SIZE:\
    box=1: boxcolor=black@0.4: boxborderw=8:\
    text='$dateString':\
    x=$PADDING:\
    y=(h - $PADDING - ascent),\
    drawtext=\
    fontfile=/Library/Fonts/PTMono.ttc:\
    fontcolor=white: alpha=0.7:\
    fontsize=$FONT_SIZE:\
    box=1: boxcolor=black@0.4: boxborderw=8:\
    text='${timeString[0,2]}\:${timeString[4,5]}':\
    x=($PADDING + $DATESTRING_W + $PADDING + $(( $minutesFromNine / $delta )) * ($PADDING + text_w)):\
    y=(h - $PADDING - ascent)"\
    $STAMPED/$videoFileName
  echo ' done.'
  processedCounter=$(( $processedCounter + 1 ))
done;
echo "\n$processedCounter processed\n\n"
SRC_VIDEOS=$STAMPED


#
# CONCAT STEP
#
echo "Concating all the videos into one."
inputList=''
filesCounter=0
for file in $SRC_VIDEOS/*.mov; do;
  inputList="$inputList -i $file"
  filesCounter=$(( $filesCounter + 1 ))
done;
concatCommand="ffmpeg $inputList -filter_complex 'concat=$filesCounter:v=1:a=1 [v] [a]' -map '[v]' -map '[a]' $RESULT -y"
eval $concatCommand
echo "\nComplete. Photolog is saved to:"
echo "\t$(cd "$(dirname "$RESULT")"; pwd)/$(basename "$RESULT")\n\n"



# if [ $hasVideos = 1 ]; then
  # ffmpeg -f concat -safe 0 -i <(for f in $OUTPUT/*.mov; do echo "file '$PWD/$f'"; done) -c copy $OUTPUT/photolog.mov -loglevel error
  # ffmpeg -i test/IMG_0163.mov -i test/IMG_0164.mov -filter_complex \
# '[0:v:0] [0:a:0] [1:v:0] [1:a:0] concat=n=2:v=1:a=1 [v] [a]' -map '[v]' -map '[a]' out.mov
  #
  #ffmpeg -i test/IMG_0167.mov -filter_complex 'concat=n=5:v=1:a=1 [v] [a]' -map '[v]' -map '[a]' out.mov 
  #
  # concatCommand="ffmpeg $inputList -filter_complex 'concat=$filesCounter:v=1:a=1 [v] [a]' -map '[v]' -map '[a]' photolog.mov -y"
  # # echo $concatCommand
  # eval $concatCommand
  # echo "Complete. Photolog is saved to: $OUTPUT/"

