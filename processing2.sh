#!/bin/bash

echo Processing phase 2...

source folder_settings.ini

THMB1=thumbnail1.jpeg
THMB2=thumbnail2.jpeg

#while true ; do

for extract_data in $(sqlite3 -init <(echo .timeout 20000) $db "select '$extracted/' || id ||','|| id ||','|| hash from checks where \
check1 = 0 and \
check2 = 0 and \
check3 = 0 and \
check4 is not null and \
check5 is not null and \
check5 > 0 and \
check6 is null and \
check7 is null") ; do

extract_path=$(echo $extract_data | cut -d, -f1)
id=$(echo $extract_data | cut -d, -f2)
hash=$(echo $extract_data | cut -d, -f3)

echo $extract_path

images=$(find $extract_path -iregex ".*.\(png\|jpg\|jpeg\)")
videos=$(find $extract_path -iregex ".*.\(mp4\|avi\|wmv\|mov\|mpeg\)")

echo $videos

check6=0

thumbdir=$(mktemp -d $extracted/THUMB_XXXXX)

# Если в папке видео, обрабатываем его не взирая на др. файлы (в т.ч. изображения)
if [ ! -z "$videos" ]
then
	echo found video. will form thumbnails from the video instead of any existing images...
	
	# Увеличить отступы для взятия проб миниатюр
	ffmpeg -i $videos -ss 00:00:0.000 -vframes 1 -loglevel quiet $thumbdir/$THMB1
	convert $thumbdir/$THMB1 -resize 300x300 $thumbdir/$THMB1
	thumbstat1=$?
	ffmpeg -i $videos -ss 00:00:1.000 -vframes 1 -loglevel quiet $thumbdir/$THMB2
	convert $thumbdir/$THMB2 -resize 300x300 $thumbdir/$THMB2
	thumbstat2=$?
	
	check6=100
	if [ $thumbstat1 -eq 1 -o $thumbstat1 -eq 1 ]
	then
		echo failed to create one or more thumbnails!
		check6=$(expr $check6 1)
	fi
	
elif  [ ! -z "$images" ]
then
	
	echo found some images. Forming thumbnails from these...
	convert $(find $extract_path -iregex ".*.\(png\|jpg\|jpeg\)" | shuf -n 5 | tail -n 1) -resize 300x300 $thumbdir/$THMB1
	thumbstat1=$?
	convert $(find $extract_path -iregex ".*.\(png\|jpg\|jpeg\)" | shuf -n 5 | tail -n 1) -resize 300x300 $thumbdir/$THMB2
	thumbstat2=$?
	
	check6=200
	if [ $thumbstat1 -eq 1 -o $thumbstat1 -eq 1 ]
	then
		echo failed to create one or more thumbnails!
		check6=$(expr $check6 1)
	fi
else
	check6=1
	echo failed to find either images or videos. Will mark it as failed
fi
echo Content type: $check6, Packing...

if [ $check6 -eq 100 -o $check6 -eq 200 ]
then
	echo "creating archive: $id --> $hash"

	tar -cf $partition/$hash.tar -C $extract_path .
	check7=$?
	
	if [ $check7 -eq 0 ] # помещаем запись в финальную таблицу
	then
	echo Inserting gallery instance...
	sqlite3 -init <(echo .timeout 20000) $db "insert into gallery \
		(partition, filename, img1, img2, description) \
		select '$PWD', hash, X'$(hexdump -ve '1/1 "%.2x"' $thumbdir/$THMB1)', \
		X'$(hexdump -ve '1/1 "%.2x"' $thumbdir/$THMB2)', filename \
		from checks where id = $id;"
	check8=$?
	echo $check8
	fi
fi

sqlite3 -init <(echo .timeout 20000) $db "update checks set check6 = $check6, \
check7 = $check7, check8 = $check8, finishtime = CURRENT_TIMESTAMP \
where id = $id"

done

#sleep 3

#done
