#!/bin/zsh
# Process photolog videos

SRC_VIDEOS=videos
# SRC_VIDEOS=test
OUTPUT=output
MONTH=09
for file in $SRC_VIDEOS/IMG*.mov; do;
  creationdate=$(ffprobe $file -show_entries format_tags=com.apple.quicktime.creationdate -v quiet -print_format compact=nokey=1:p=0)
  videoFileName=$(basename "$file")
  fileMonth=${creationdate[6,7]}
  if [ $fileMonth != $MONTH ]; then
    echo Skipping $videoFileName with creation date $creationdate
  else;
    echo Processing $videoFileName
    dateString=$(date -j -f "%Y-%m-%d" ${creationdate[0,10]} "+%a %d %b %Y")
    timeString=${creationdate[12,16]}
    hours=$(( ${timeString[0,2]} ))
    minutes=$(( ${timeString[4,5]} ))
    minutesFromMidnight=$(( $hours * 60 + $minutes ))
    nineOClock=$(( 9 * 60 ))
    minutesFromNine=$(( minutesFromMidnight - nineOClock ))
    delta=183
    echo -n "\tadding timestamp: ‘$dateString $timeString’..."
    ffmpeg -i $file -y \
      -codec:a copy \
      -loglevel error\
      -vf "drawtext=\
        fontfile=/Library/Fonts/PTMono.ttc:\
        fontcolor=white: alpha=0.7:\
        box=1: boxcolor=black@0.4: boxborderw=8:\
        text='$dateString':\
        x=16:\
        y=(h-32),\
      drawtext=\
        fontfile=/Library/Fonts/PTMono.ttc:\
        fontcolor=white: alpha=0.7:\
        box=1: boxcolor=black@0.4: boxborderw=8:\
        text='${timeString[0,2]}\:${timeString[4,5]}':\
        x=(174 + 16 + $(( $minutesFromNine / $delta )) * (16 + text_w)):\
        y=(h-32)"\
      $OUTPUT/$videoFileName
    echo ' Done.'
  fi;
done;
