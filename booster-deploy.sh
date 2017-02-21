#!/bin/sh
echo "$@"

#copying booster spec to /files
cp "$1" /files/

java -jar /sunshine/sunshine.jar transform -n "Generate SQL" -p /files/ -l /booster2/Booster2/ -i /files/`basename $1`

SQL_FILE_NAME=`basename $1 boo2`generated.sql

mysql -u root < /files/$SQL_FILE_NAME

DB_NAME=$(grep -i "^create database" /files/$SQL_FILE_NAME | grep -o "\`[^\`]*\`" | tr -d '`')

mkdir /usr/local/tomcat/webapps/${DB_NAME}

unzip -d -o /usr/local/tomcat/webapps/${DB_NAME} /booster2/gwi.war

sed -i "s-<dbname>.*</dbname>-<dbname>${DB_NAME}</dbname>-g" /usr/local/tomcat/webapps/${DB_NAME}/WEB-INF/dbConfig.xml   

sed -i "s-> James Welch <-> ${DB_NAME} User <-g" /usr/local/tomcat/webapps/${DB_NAME}/index.html 


