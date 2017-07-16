from bottle import route, run, template, debug, static_file
import sqlite3

DB = sqlite3.connect("gallery")

debug(True)

def getLast():
    cursor = DB.cursor()
    cursor.execute("select * from checks order by finishtime desc limit 100")
    html_rows = cursor.fetchall()
    cursor.close()
    return html_rows

@route('/static/css/<style>')
def stylesheets(style):
    return static_file(style, root='./static/css')

@route('/Journal')
def index():
    rows = getLast()
    return template("states_table", rows=rows)


run(host='localhost', port=8080)
