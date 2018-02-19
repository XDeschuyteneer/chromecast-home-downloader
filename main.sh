#!/usr/bin/env bash

# list of tools used in this project
REQUIRES="xmllint xdpyinfo"

# default values
DEFAULT_BUILDDIR=./build
DEFAULT_IMGDIR=${DEFAULT_BUILDDIR}/img
DEFAULT_RETRIES=5

# init values
BUILDDIR=${DEFAULT_BUILDDIR}
IMGDIR=${DEFAULT_IMGDIR}
RETRIES=${DEFAULT_RETRIES}

# parsing parameters
while getopts "b:o:r:" opt; do
  case $opt in
    b)
      export BUILDDIR=${OPTARG}
      ;;
    o)
      export IMGDIR=${OPTARG}
      ;;
    r)
      export RETRIES=${OPTARG}
      ;;
    \?)
      echo "Usage: $0 [OPTIONS]"
      echo "\t-b DIR : build artifacts directory (default : ${DEFAULT_BUILDDIR})"
      echo "\t-o DIR : download image directory (default : ${DEFAULT_IMGDIR})"
      echo "\t-r NUM : number of retries to refresh the chromecast homepage wallpaper list (default : ${DEFAULT_RETRIES})"
      ;;
  esac
done

# ensure all required tools are installed
for tool in ${REQUIRES}; do
    if ! [ -x "$(command -v ${tool})" ]; then
        echo "Error: ${tool} is not installed." >&2
        exit 1
    fi
done

# setup of the env
mkdir -p ${BUILDDIR}
mkdir -p ${IMGDIR}

# calculate the screen resolution
SCREEN_RESOLUTION=$(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/')
SCREEN_X=$(echo ${SCREEN_RESOLUTION} | awk -F 'x' '{print $1}')
SCREEN_Y=$(echo ${SCREEN_RESOLUTION} | awk -F 'x' '{print $2}')

# download the images
IMG_COUNT_ORIG=$(ls -l ${IMGDIR} | wc -l)
IMG_COUNT=0
while [ ${IMG_COUNT} -ne $(ls -l ${IMGDIR} | wc -l) ]; do
    IMG_COUNT=$(ls -l ${IMGDIR} | wc -l)
    for i in $(seq 0 ${RETRIES}); do
        wget -q https://clients3.google.com/cast/chromecast/home -O ${BUILDDIR}/index.html
        cat ${BUILDDIR}/index.html | grep -o -e "https:[^,]*googleusercontent\.com[^,]*" | sed -e "s/\\\\\//\//g" | sed -e "s/\\\\\\\\u003d/=/g" | sed -e "s/\\\\x22//g" | sed -e "s/s1280-w1280-h720/s${SCREEN_X}-w${SCREEN_X}-h${SCREEN_Y}/g" > ${BUILDDIR}/url.txt
        mkdir -p ${IMGDIR}
        wget -q -nc -i ${BUILDDIR}/url.txt -P ${IMGDIR}
    done
done
IMG_COUNT_END=$(ls -l ${IMGDIR} | wc -l)
IMG_COUNT_DL=$((${IMG_COUNT_END} - ${IMG_COUNT_ORIG}))
echo "total DL: ${IMG_COUNT_DL}"