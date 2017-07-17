#!/bin/bash

echo Processing phase 2...

source folder_settings.ini

THMB1=thumbnail1.jpeg
THMB2=thumbnail2.jpeg

while true ; do

for extract_path in $(sqlite3 -init <(echo .timeout 20000) $db "select '$extracted/' || id from checks where \
check1 = 0 and \
check2 = 0 and \
check3 = 0 and \
check4 is not null and \
check5 is not null and \
check5 > 0 and \
check6 is null and \
check7 is null") ; do

echo $extract_path

images=$(find $extract_path -iregex ".*.\(png\|jpg\|jpeg\)")
videos=$(find $extract_path -iregex ".*.\(mp4\|avi\|wmv\|mov\|mpeg\)")

echo $videos

check6=0

thumbdir=$(mktemp -d $extracted/THUMB_XXXXX)

if [ ! -z "$videos" ]
then
	echo found video. will form thumbnails from the video instead of any existing images...
	check6=100
	# Увеличить отступы для взятия проб миниатюр
	ffmpeg -i $videos -ss 00:00:0.000 -vframes 1 -loglevel quiet $thumbdir/$THMB1
	thumbstat1=$?
	ffmpeg -i $videos -ss 00:00:1.000 -vframes 1 -loglevel quiet $thumbdir/$THMB2
	thumbstat2=$?
	
	if [ $thumbstat1 -eq 1 -o $thumbstat1 -eq 1 ]
	then
		echo failed to create one or more thumbnails!
		check6=$(expr $check6 1)
	fi
	
elif  [ ! -z "$images" ]
then
	echo found some images. Forming thumbnails from these...
	# cp ${images[$RANDOM % ${#images[@]} ]} $thumbdir/$THMB2
	# find $extract_path -iregex ".*.\(png\|jpg\|jpeg\)" | shuf -n 5 | tail -n 1

	check6=200
fi


echo Content type: $check6

done

sleep 3

done
