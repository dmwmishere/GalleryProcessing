#!/bin/bash

source folder_settings.ini

# test stuff:
# cp $install_path/TEST_FILES/* $source

# Проверка открыт ли файл
# ввод: имя файла
# вывод: 2 - не задан пар-р, 1 - файл открыт, 0 - ок
check0_lsof_exist(){
	if [ -z "$1" ]
	then
		return 2
	fi
	echo Checking lsof: $1
	if [ -z "$(lsof "$1")" ]
	then
		return 0
	else
		return 1
	fi
}

# Проверка на наличие в файле недопустимых символов
# ввод: имя файла
# вывод: 2 - не задан пар-р, 1 - недопустимое имя, 0 - ок
check1_file_name(){
	if [ -z "$1" ]
	then
		return 2
	fi
	echo Checking file name: $1
	if [[ $1 =~ .*[\!\@\#\$\%\^\&\*\(\)\+\'\"\;\,\ ].* ]];
	then
		return 1
	else
		return 0
	fi
}

# Проверка на принодлежность расширения к одному из поддерживаемых типов
# ввод: расширение файла (tar, txt)
# вывод: 2 - не задан пар-р, 1 - не поддерживается, 0 - ок
check2_file_extension(){
	if [ -z "$1" ]
	then
		return 2
	fi
	echo Checking extension: ${1,,}
	case ${1,,} in
		zip|rar|mp4|avi|wmv|mov|mpeg) return 0;;
		*) return 1;;
	esac
	
}

# Проверка на наличие файла в базе данных
# ввод: контрольная сумма файла
# вывод: 2 - не задан пар-р, 1 - существует в БД, 0 - ок
check3_exist_in_db(){
	if [ -z "$1" ]
	then
		return 2
	fi
	echo Checking in DB: $1
	db_result=$(sqlite3 -init <(echo .timeout 20000) $db "select count(*) from gallery where filename = '$file_md5'")
	if [ "$db_result" -eq 1 ]
	then
		return 1
	else
		return 0
	fi
	
}

while true ; do

# Проверяет условия для каждого файла
for file in $source/*\.* ; do

if [ ! -f "$file" ]
then
	echo no files found
	continue
fi

echo STARTING WITH $file

check0_lsof_exist "$file"
check0_rs=$?
# Если файл открыт, попробовать на следующей итерации
if [ $check0_rs -eq 1 ]
then
	echo the file is still opened! Wait til it will be closed.
	continue
fi

filename1=$(basename "$file") # имя + расширение
extension="${filename1##*.}" # расширение
filename="${filename1%.*}" # имя
file_md5=$(md5sum "$file" | cut -d' ' -f1) # контрольная сумма

# Буферная таблица для дальнейших фаз обработки
dbid=$(sqlite3 -init <(echo .timeout 20000) $db "insert into checks (hash, filename) values ('$file_md5', '$(echo -e "$(basename "$file")" | tr \' ?)'); select last_insert_rowid()")

echo dbid=$dbid

check1_file_name "$filename"
check1_rs=$?

check2_file_extension "$extension"
check2_rs=$?

check3_exist_in_db "$file_md5"
check3_rs=$?

echo check states: lsof = $check0_rs, filename = $check1_rs, extension = $check2_rs, db = $check3_rs

# Если жотя бы одна из проверок не пройдена в FAILED, иначе на дальнейшую обработку.
if [ $check1_rs -eq 1 -o $check2_rs -eq 1 -o $check3_rs -eq 1 ]
then
	mv "$file" "$failed/$filename1"
else
	mv "$file" "$process/$file_md5-$(($dbid+0))-$filename1"
	# FIXME: ${dbid:1} если используем sqlite3 с инициирующим файлом, в выводе будет лишний байт. Исследовать и убрать неопределенность
fi

# Выставляет рез-ты проверок в буферную таблицу
sqlite3 -init <(echo .timeout 20000) $db "update checks set check0 = $check0_rs, check1 = $check1_rs, check2 = $check2_rs, check3 = $check3_rs where id = $dbid"

done

sleep 3

done
