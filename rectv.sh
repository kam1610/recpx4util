#!/bin/bash

if [ $# -ne 3 ]; then
    echo "usage: rectv.sh [chnum] [duration in min] [dstfile]" 1>&2
    echo "       using /dev/px4-DTV2   " 1>&2
    exit 1
fi


DURATION=`echo "scale=2; 60 * $2" | bc`
DURATION=`printf "%.0f" ${DURATION}`

/usr/local/bin/recpx4      \
    --b25                  \
    --device /dev/px4-DTV2 \
    $1                     \
    ${DURATION}            \
    ${3}.ts

#     --sid    hd            \

AV_LOG_FORCE_NOCOLOR=1 ffmpeg \
    -y                        \
    -fflags +discardcorrupt   \
    -loglevel error           \
    -i ${3}.ts                \
    -vcodec  libx264          \
    -s       720x480          \
    -aspect  16:9             \
    -pix_fmt yuv420p          \
    -crf     19               \
    -acodec  copy             \
    -bsf:a   aac_adtstoasc    \
    -f       mp4              \
    ${3}.mp4                  \
    -analyzeduration 30M      \
    2>&1 |tee ${3}.mp4.log

#    -bsf:v   h264_mp4toannexb \


