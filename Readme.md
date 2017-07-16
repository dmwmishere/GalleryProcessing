
Создать таблицу со статусами проверок файла.
В нее вставляется в preprocess2.sh

create table checks (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	hash text not null, -- контрольная сумма файла (md5)
	filename text not null, -- полное имя файла
	check0 integer, -- файл не открыт где-то еще
	check1 integer, -- имя файла допустимо
	check2 integer, -- расширение допустимо
	check3 integer, -- хэш код отсутствует в БД
	check4 integer, -- архив распакован / медиа перемещено
	check5 integer, -- существувют медиа файлы в папке
	check6 integer,
	check7 integer,
	desicion integer, -- резолюция по файлу
	starttime datetime NOT NULL default CURRENT_TIMESTAMP, -- время занесения записи в эту таблицу
	phase1time datetime, -- время прохождения 1ой фазы (processing.sh)
	finishtime datetime -- время завершения
);

Добавить индекс для ускорения поиска:

CREATE INDEX "idx_filename" on checks (filename ASC)

