#!/bin/bash

# Скрипт выполняет следующие проверки:
# 1. Имя файла на наличие специальных символов
# 2. Открыт ли файл на момент проверки
# 3. Хэш код файла в БД
# 4. Расширение (архивы / мультимедиа)
# 5. TODO: Проверка архива / мультимедиа

source folder_settings.ini

# test stuff:
cp $install_path/TEST_FILES/* $source
# rm ./FAILED/* ./PROCESS/* ./DUPLICATES/*
# tree DUPLICATES/ PROCESS/ SOURCE/ FAILED/ TEST_FILES/

#while true ; do # this loop is for testing purposes only. you need to place this into cron scheduler

supported_list=$(printf "\\|%s" "${supported_files[@]}")
supported_list=${supported_list:2}
echo SUPPORTED FILES: $supported_list

for file in $(find $source -type f -not -iregex ".*\.\(zip\|rar\|mp4\|avi\|wmv\|mov\|mpeg\)" -printf '%f\n') ; do
	echo Unsupported file found: $file. Will move it to FAILED
	mv -T "$source/$file" $failed/$(basename "$file")
done

for file in $source/*\.* ; do
	if [ -f "$file" ] # это файл?
	then
		isOpened=$(lsof | grep "${file#"./"}")
		if [ "$isOpened" == "" ] # и он не открыт?
		then
			fixed_name=$(echo $file | tr -d \!\@\#\$\%\^\&\*\(\)\+\'\"\;\,\ )
			if [ "$file" != "$fixed_name" ] # Имя файла не содержит спец. символов
			then
				echo 1.1. renaming file from $file to $fixed_name
				mv -T "$file" "$fixed_name"
			else
				echo 1.2. Filename \"$fixed_name\" check PASSED
			fi
			file_md5=$(md5sum $fixed_name | cut -d' ' -f1)
			db_result=$(sqlite3 $db "select count(*) from gallery where filename = '$file_md5'")
			if [ "$db_result" -eq 1 ] # Хэш код файла отсутствует в БД
			then
				echo 2.1. file $fixed_name with $file_md5 exists in database!
				mv $fixed_name $duplicates/$(basename $fixed_name)
			else
				echo 2.2. MD5 check PASSED
				mv $fixed_name $process/$file_md5-$(basename $fixed_name)
			fi
		else
			echo 0.0. $file opened somewhere!
		fi # is opened
	fi # is file
done

#done # while
