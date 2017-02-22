#!/bin/sh
echo "$@"

lockdir=/var/tmp/booster-deploy
pidfile=/var/tmp/booster-deploy/pid

if ( mkdir ${lockdir} ) 2> /dev/null; then
        echo $$ > $pidfile
        trap 'rm -rf "$lockdir"; exit $?' INT TERM EXIT
        # do stuff here

#copying booster spec to /files
cp "$1" /files/

java -jar /sunshine/sunshine.jar transform -n "Generate SQL" -p /files/ -l /booster2/Booster2/ -i /files/`basename $1`

SQL_FILE_NAME=`basename $1 boo2`generated.sql

mysql -u root < /files/$SQL_FILE_NAME

DB_NAME=$(grep -i "^create database" /files/$SQL_FILE_NAME | grep -o "\`[^\`]*\`" | tr -d '`')

mkdir /usr/local/tomcat/webapps/${DB_NAME}

unzip -o -d /usr/local/tomcat/webapps/${DB_NAME} /booster2/gwi.war

sed -i "s-<dbname>.*</dbname>-<dbname>${DB_NAME}</dbname>-g" /usr/local/tomcat/webapps/${DB_NAME}/WEB-INF/dbConfig.xml   

sed -i "s-> James Welch <-> ${DB_NAME} User <-g" /usr/local/tomcat/webapps/${DB_NAME}/index.html 

sed -i "s-gwi-${DB_NAME}-g" /usr/local/tomcat/webapps/${DB_NAME}/js/script.js

rm -rf "$1"

        # clean up after yourself, and release your trap
        rm -rf "$lockdir"
        trap - INT TERM EXIT
else
        echo "Lock Exists: $lockdir owned by $(cat $pidfile)"
fi

