# coding=utf-8
import hashlib
import logging
import os
import os.path as pth
import shutil
import sqlite3
import sys
import tarfile
from ConfigParser import ConfigParser
from subprocess import call
from time import time, ctime

print(sys.version)
config = ConfigParser()
config.read('settings.ini')
SECTION = 'Prepare'

# Логирование:
logging_level = logging.INFO
log = logging.getLogger('prepare')
formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
fh = logging.FileHandler('preparation.log')
fh.setFormatter(formatter)
ch = logging.StreamHandler()
ch.setFormatter(formatter)
log.addHandler(fh)
log.addHandler(ch)
log.setLevel(logging_level)

# Директорию для хранения архивов
db_home = config.get(SECTION, 'source.dir')
# Имя БД с описаниями
db_name = config.get(SECTION, 'source.db')
# Директория с входными файлами

# /media/dmwm/A2140DE4140DBC73/Users/DMWM/Documents/DMWM/LE   /home/dmwm/Documents/NEW
target_dir = pth.abspath(config.get(SECTION, 'target.dir'))

log.info(
    'Started at %s\nSettings:\ndb_home=%s,\ndb_name=%s,\ntarget=%s' % (ctime(time()), db_home, db_name, target_dir))

# Утилиты для распаковки и формат их вызова
UNZIP = "unzip '{}' -d {}"
UNRAR = "unrar e '{}' {}  -y"

# Утилиты для генерации сэмплов
IMAGE_CONVERTER = "convert \"{}\" -resize 300x300 {}"
VIDEO_THUMBNAIL = "ffmpeg -i '{}' -ss 00:00:{}.000 -vframes 1 {}.jpeg"

# Поддерживаемые форматы и утилиты для работы с ними
ARCS = {".zip": UNZIP, ".rar": UNRAR, ".ZIP": UNZIP, ".RAR": UNRAR}
MEDS = (".avi", ".mp4", ".AVI", ".MP4", ".wmv", ".WMV", ".mov", ".MOV", ".mpeg", ".MPEG")

gallery = pth.abspath(pth.join(db_home, db_name))  # Полный путь к БД

if not pth.exists(gallery):
    log.error("ERROR CONNECTION GALLERY!")
    exit(-1)

DB = sqlite3.connect(gallery)

devnull = open(os.devnull, "w")

# Здесь файлы из target_dir с к-ми будет работать скрипт
archives, medias = [], []

for any_file in os.listdir(target_dir):
    # Разбить файлы из target_dir по соответствующим массивам
    # TODO: Проверить допустимость имени файла
    # TODO: Если некорректно запросить переименование
    if pth.splitext(any_file)[1] in ARCS:
        archives.append(pth.join(target_dir, any_file))
    elif pth.splitext(any_file)[1] in MEDS:
        medias.append(pth.join(target_dir, any_file))
    else:
        log.error("UNSUPPORTED FILE: " + any_file)

# archives = [pth.join(target_dir, file) for file in filter(lambda x: pth.splitext(x)[1] in ARCS os.listdir(target_dir))];
# medias   = [pth.join(target_dir, file) for file in filter(lambda x: pth.splitext(x)[1] in MEDS os.listdir(target_dir))];

log.debug("All files in directory: %s", os.listdir(target_dir))
log.debug("Supported files in directory: %s", archives + medias)

def preparedirectory(filename, parent_dir):
    extpath = pth.join(parent_dir, filename)
    if not pth.exists(extpath):
        log.debug("PATH DOES NOT EXIST! MAKING DIR...")
        os.mkdir(pth.join(extpath))
        return extpath
    else:
        log.info("PATH DOES EXIST! SKIPPING: %s", parent_dir)
        return

def nothumbs(init_dir):
    if (not pth.exists(pth.join(init_dir, "thumb-1"))) or (not pth.exists(pth.join(init_dir, "thumb-2"))):
        log.warning("NO THUMBNAILS FOUND...")
        shutil.copyfile("noimag.png", pth.join(init_dir, "thumb-1"))
        shutil.copyfile("noimag.png", pth.join(init_dir, "thumb-2"))


def checkarc(init_dir):
    for _, _, files in os.walk(init_dir, topdown=False):
        for arc_file in files:
            if pth.splitext(arc_file)[1] in MEDS:
                log.info("COMMAND: %s", VIDEO_THUMBNAIL.format(pth.join(init_dir, pth.normpath(arc_file)), 10,
                                                               pth.join(init_dir, "thumb-1")))
                call(VIDEO_THUMBNAIL.format(pth.join(init_dir, pth.normpath(arc_file)), 15, pth.join(init_dir, "thumb-1")),
                     shell=True)
                call(VIDEO_THUMBNAIL.format(pth.join(init_dir, pth.normpath(arc_file)), 30, pth.join(init_dir, "thumb-2")),
                     shell=True)
                # noThumbs(init_dir);


def processarc(arc_file, newname, outputdir):  # Обработка архивных файлов
    log.info("ARCHIVE - %s --> %s", arc_file, newname)
    extpath = preparedirectory(newname, outputdir)
    log.info("COMMAND: %s", ARCS[pth.splitext(arc_file)[1]].format(arc_file, extpath))
    if extpath:
        call(ARCS[pth.splitext(arc_file)[1]].format(arc_file, extpath), shell=True, stdout=devnull)
        checkarc(extpath)
    return extpath


def processmed(med_file, newname, outputdir):  # Обработка других файлов
    log.info("MEDIA - %s --> %s", med_file, newname)
    extpath = preparedirectory(newname, outputdir)
    if extpath:
        shutil.copy(med_file, extpath)
        log.info("COMMAND: %s",
                 VIDEO_THUMBNAIL.format(pth.join(extpath, pth.normpath(med_file)), 10, pth.join(extpath, "thumb-1")))
        call(VIDEO_THUMBNAIL.format(pth.join(extpath, pth.normpath(med_file)), 15, pth.join(extpath, "thumb-1")),
             shell=True)
        call(VIDEO_THUMBNAIL.format(pth.join(extpath, pth.normpath(med_file)), 30, pth.join(extpath, "thumb-2")),
             shell=True)
        # noThumbs(init_dir);
    return extpath


def getsamples(init_path):
    for dirpath, _, files in os.walk(init_path, topdown=False):
        if files:
            # Не учитывать файлы не изображения (html, txt, ...)
            sample1 = pth.join(dirpath, sorted(
                filter(lambda x: pth.splitext(x)[1] in (".png", ".jpg", ".jpeg", ".gif", ".JPG", ".JPEG"), files))[0])
            sample2 = pth.join(dirpath, sorted(
                filter(lambda x: pth.splitext(x)[1] in (".png", ".jpg", ".jpeg", ".gif", ".JPG", ".JPEG"), files))[
                1])  # random.randint(2, len(files)//2)
            return sample1, sample2


def packdir(init_path, target_path, filename):
    log.debug("INIT_PATH: %s, TARGET_PATH: %s", init_path, pth.join(target_path, filename + ".tar"))
    with tarfile.open(pth.join(target_path, filename + ".tar"), "w") as tar:
        for dirpath, _, files in os.walk(init_path, topdown=False):
            log.debug("FILE: " + str(files))
            #             print("PACKING: " + pth.abspath(files));
            map(lambda f: tar.add(f, arcname=pth.basename(f)), map(lambda f: pth.join(dirpath, f), files))
            return


# tar.add(pth.abspath(files), arcname=pth.basename(files));

def insert2gallery(filename, partition="", sample1=None, sample2=None, description="none", modelid=0, tagid=0, pswd=""):
    cursor = DB.cursor()
    cursor.execute(
        "insert into gallery (partition, filename, img1, img2, description, password) values (?, ?, ?, ?, ?, ?)",
        (partition, filename, sample1, sample2, description, pswd))
    DB.commit()
    cursor.close()
    return


def checkingallery(filehash):
    cursor = DB.cursor()
    cursor.execute("select count(*) from gallery where filename = ?", (filehash,))
    cnt = cursor.fetchone()[0]
    result = False if cnt < 1 else True
    cursor.close()
    return result


if __name__ == "__main__":
    i = 0
    e = 0
    s = 0
    for any_file in archives + medias:
        filehash = hashlib.md5(open(any_file, "rb").read()).hexdigest()
        if checkingallery(filehash):
            s += 1
            log.warning('FILE \"%s\" WITH HASH %s EXISTS! SKIP.', any_file, filehash)
            continue
        try:
            extracted = processarc(any_file, filehash, target_dir) if any_file in archives else processmed(any_file, filehash,
                                                                                                           target_dir)
            if extracted:
                sample1, sample2 = getsamples(extracted)
                log.debug("SAMPLES: %s, %s", sample1, sample2)
                sample1_path = pth.join(target_dir, filehash + "-1")
                sample2_path = pth.join(target_dir, filehash + "-2")
                log.debug("Image convert: " + IMAGE_CONVERTER.format(sample1, sample1_path))
                log.debug("Image convert: " + IMAGE_CONVERTER.format(sample2, sample2_path))
                call(IMAGE_CONVERTER.format(sample1, sample1_path), shell=True, stdout=devnull)
                call(IMAGE_CONVERTER.format(sample2, sample2_path), shell=True, stdout=devnull)
                s1, s2 = None, None
                with open(sample1_path, "rb") as sample1_blob, open(sample2_path, "rb") as sample2_blob:
                    s1 = sample1_blob.read()
                    s2 = sample2_blob.read()
                insert2gallery(filename=filehash, description=pth.basename(any_file), sample1=sqlite3.Binary(s1),
                               sample2=sqlite3.Binary(s2))
                packdir(extracted, pth.abspath(db_home), filehash)
                shutil.rmtree(extracted)
                os.remove(extracted + "-1")
                os.remove(extracted + "-2")
        except Exception, ex:
            e += 1
            log.error("ERROR WHILE PROCESSING FILE: " + any_file)
            log.error(ex)
            if pth.exists(extracted):
                shutil.rmtree(extracted)
        else:
            i += 1
            log.info("FILE ADDED SUCCESSFULLY: %s %s", any_file, filehash)

    log.info("supported files found: %d\npassed: %d\nfailed: %d\nskipped: %d", len(archives) + len(medias), i, e, s)
