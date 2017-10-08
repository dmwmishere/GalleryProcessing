# Описание


# Предусловия
* Создать таблицу со статусами проверок файла.
В нее вставляется в preprocess2.sh
create table checks (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	hash text not null, -- контрольная сумма файла (md5)
	filename text not null, -- полное имя файла
	check0 integer, -- файл не открыт где-то еще (0 - pass)
	check1 integer, -- имя файла допустимо (0 - pass)
	check2 integer, -- расширение допустимо (0 - pass)
	check3 integer, -- хэш код отсутствует в БД (0 - pass)
	check4 integer, -- архив распакован / медиа перемещено (0 - pass, else - archiver result code)
	check5 integer, -- существувют медиа файлы в папке (0 - fail, else - file count)
	check6 integer, -- генерация миниатюр
	check7 integer, -- запаковка
	check8 integer, -- запись в табл. gallery
	desicion integer, -- резолюция по файлу
	starttime datetime NOT NULL default CURRENT_TIMESTAMP, -- время занесения записи в эту таблицу
	phase1time datetime, -- время прохождения 1ой фазы (processing.sh)
	finishtime datetime -- время завершения
);
* Добавить индекс для ускорения поиска:
CREATE INDEX "idx_filename" on checks (filename ASC)
* Добавить таблицу:
CREATE TABLE gallery (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    partition TEXT NOT NULL,
    filename TEXT NOT NULL UNIQUE, --UNIQUE
    img1 BLOB,
    img2 BLOB,
    description TEXT,
    password BLOB,
    timeadded datetime not null default current_timestamp
)

# Установка и запуск

Предусловия:

устаносить sqlite3, lsof, 

задать путь папок в folder_settings.ini

* выполнить install.sh (будут созраны рабочие директории)
* запустить preprocess0.sh - выполняет ряд общих проверок и переносит файл в PROCESS
* запустить processing.sh - выполняет проверки по контенту файла и распаковывает/переносит файл в EXTRACTED

# Ограничения
* В архиве может находиться не более одного видео
