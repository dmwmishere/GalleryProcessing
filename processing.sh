#!/bin/bash

source folder_settings.ini

while true ; do

# Обрабатывает каждый файл
# Берем файлы по выборке из БД т.о. гарантирует (1) файл не открыт, 
# т.к. запись в БД идет после перемещения, и 
# (2) возможные блокировки БД и отсутствие записи при имеющемся файле
for file in $(sqlite3 -init <(echo .timeout 20000) $db "select '$process/' || hash ||'-'|| id || '-' || filename from checks where \
check1 = 0 and \
check2 = 0 and \
check3 = 0 and \
check4 is null and \
check5 is null") ; do
# !!!По итогам всех действий определяется удалять файл или нет (ДЛЯ ОТЛАДКИ !!!)
final_state=0

# Количество подходящих файлов. Успешно если > 0
valid_files_count=0

filename1=$(basename "$file") # имя + расширение
extension="${filename1##*.}" # расширение
filename="${filename1%.*}" # имя
file_md5=${filename%%-*} # контрольная сумма
dbid=$(expr "$filename" : '^[[:alnum:]]*-\([[:digit:]]*\)-') # id в БД

# Проверить что файл существует
# продумать механизм записи статуса в БД
if [ ! -f "$file" ]
then
	echo Failed to read file "$file" !
	continue
fi

echo STARTING WITH $file

if [ ! ${#file_md5} -eq 32 ]
then
	echo "md5 not valid! moving 2 failed"
	mv "$file" "$failed/$filename1"
	final_state=1
	continue
fi

echo $file_md5

extract_path=$extracted/$dbid

mkdir $extract_path

extract_rs=99

# Файл распаковывается (если архив) в EXTRACTED или копируется (если медиа)
case ${extension,,} in
	zip)
		unzip -o -q "${file}" -d "$extract_path" 
		extract_rs=$?
		;;
	rar)
		unrar e -p- "${file}" "$extract_path" -y -inul
		extract_rs=$?
		;;
	mp4|avi|wmv|mov|mpeg)
		cp "$file" "$extract_path"
		extract_rs=$?
		;;
	*)
		echo failed to extract!
		;;
esac

# Если ошибка при распаковке архива, перемещяем в FAILED и удаляем каталог в EXTRACTED
if [ ! $extract_rs -eq 0 ]
then
	echo failed to extract archive, check log for more info! moving file to failed directory
	mv "$file" "$failed/$filename1"
	# rm -d $extracted/$file_md5 # Чистку ошибочных каталогов вынести в postprocess
	final_state=2
	# continue # тут скипнуть нельзя т.к. статус надо записать и успешный тоже
else
	# Проверить содержимое в EXTRACTED. Тут задаются возможные форматы
	valid_files_count=$(find $extract_path -iregex ".*.\(mp4\|png\|jpg\|jpeg\|avi\|wmv\|mov\|mpeg\)" | wc -l)
	if [ $valid_files_count -eq 0 ]
	then
		echo no images or media found!
		mv "$file" "$failed/$filename1"
		# rm -r $extract_path # Чистку ошибочных каталогов вынести в postprocess
		final_state=3
	fi
fi

sqlite3 -init <(echo .timeout 20000) $db "update checks set check4 = $extract_rs, check5 = $valid_files_count where id in (select max(id) from checks where id = $dbid)"


if [ $final_state -eq 0 ]
then
	echo PIPELINE PASSED. REMOVING...
	rm -v "$file" # !!! удалять только при успешном прохождении всех фаз (пусть в postprocess)
fi

done

sleep 3

done
