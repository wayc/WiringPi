import os
import urllib2
import json
import MySQLdb

MYSQL_HOST	= ""
MYSQL_USER	= ""
MYSQL_PASSWD	= ""
MYSQL_DB	= ""

WXUG_API_KEY = ""


f = urllib2.urlopen('')
json_string = f.read()

parsed_json = json.loads(json_string)

location = parsed_json['location']['city']

temp_f = parsed_json['current_observation']['temp_f']
epoch_utc = parsed_json['current_observation']['observation_epoch']

print "Current temperature in %s is: %s" % (location, temp_f)
f.close()



conn = MySQLdb.connect(host=MYSQL_HOST, user=MYSQL_USER, passwd=MYSQL_PASSWD, db=MYSQL_DB)
x = conn.cursor()

try:
	query = "INSERT INTO table VALUES(%s,%s)" % (epoch_utc,temp_f)
	x.execute(query)
	conn.commit()
except:
	print "MySQL error."
	conn.rollback()
conn.close()


