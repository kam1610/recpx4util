#!/bin/bash

if [ $# -ne 3 ]; then
    echo "usage: rectv.sh [chnum] [duration in min] [dstfile]" 1>&2
    echo "       using /dev/px4-DTV3   " 1>&2
    exit 1
fi


DURATION=`echo "scale=2; 60 * $2" | bc`
DURATION=`printf "%.0f" ${DURATION}`

/usr/local/bin/recpx4      \
    --b25                  \
    --strip                \
    --sid    hd            \
    --device /dev/px4-DTV2 \
    $1                     \
    ${DURATION}            \
    -                      \
|                          \
ffmpeg                     \
    -y                     \
    -i                     \
    -                      \
    -vcodec  libx264       \
    -s       720x480       \
    -aspect  16:9          \
    -pix_fmt yuv420p       \
    -crf     19            \
    -acodec  copy          \
    -f       mp4           \
    $3
