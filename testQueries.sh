sqlite3 -init <(echo .timeout 20000) gallery "select * from checks where \
check1 = 0 and \
check2 = 0 and \
check3 = 0 and \
check4 is null and \
check5 is null"

somedir="./test/"
for line in $(sqlite3 -init <(echo .timeout 20000) gallery "select '$somedir' || hash ||'-'|| filename from checks where \
check1 = 0 and \
check2 = 0 and \
check3 = 0 and \
check4 is null and \
check5 is null") ; do
echo FILE:$line
done

sqlite3 -init <(echo .timeout 20000) gallery "select hash, filename from checks where \
check1 = 0 and \
check2 = 0 and \
check3 = 0 and \
check4 is null and \
check5 is null" | grep "|"


./preprocess0.sh > log-preprocess.log & 
./processing.sh > log-processing.log


dbid=$(sqlite3 -init <(echo .timeout 20000) gallery "insert into checks (hash, filename) values ('$file_md5', '$(echo -e "$(basename "$file")" | tr \' ?)'); select last_insert_rowid()") ; echo dbid=$dbid



filename=md5-666-qwer-f12-11-file.ext ; echo `expr "$filename" : '.*-\(.*\)-.*'`


