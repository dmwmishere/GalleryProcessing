%#template to generate a HTML table from a list of tuples (or list of lists, or tuple of tuples or ...)
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="static/css/styles.css">
</head>
<body>
<table border="1">
<tr>
	<td>id</td>
	<td>MD5</td>
	<td>Имя файла</td>
	<td>Файл открыт</td>
	<td>Имя файла</td>
	<td>Расширение</td>
	<td>Хэш код в БД</td>
	<td>Распаковка</td>
	<td>Контент</td>
	<td>Проверка 6</td>
	<td>Проверка 7</td>
	<td>Решение</td>
	<td>Начало обработки</td>
	<td>Конец 1й фазы</td>
	<td>Конец обработки</td>
	</tr>
%for row in rows:
  <tr>
  %for col in row:
    <td>{{col}}</td>
  %end
  </tr>
%end
</table>
</body>
</html>
