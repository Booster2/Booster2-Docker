#!/bin/sh

# MySQL parts are based on the run script from kost/docker-alpine (with thanks!)
# https://github.com/kost/docker-alpine/blob/master/alpine-mariadb/scripts/run.sh


# execute any pre-init scripts, useful for images
# based on this image
for i in /scripts/pre-init.d/*sh
do
	if [ -e "${i}" ]; then
		echo "[i] pre-init.d - processing $i"
		. "${i}"
	fi
done

echo "log_bin_trust_function_creators=1" >> /etc/mysql/my.cnf

if [ ! -d "/run/mysqld" ]; then
	mkdir -p /run/mysqld
	chown -R mysql:mysql /run/mysqld
fi

if [ -d /var/lib/mysql/mysql ]; then
	echo "[i] MySQL directory already present, skipping creation"
else
	echo "[i] MySQL data directory not found, creating initial DBs"

	chown -R mysql:mysql /var/lib/mysql

	mysql_install_db --user=mysql > /dev/null

	if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
		MYSQL_ROOT_PASSWORD=""
		echo "[i] MySQL root Password: $MYSQL_ROOT_PASSWORD"
	fi

	MYSQL_DATABASE=${MYSQL_DATABASE:-""}
	MYSQL_USER=${MYSQL_USER:-""}
	MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

	tfile=`mktemp`
	if [ ! -f "$tfile" ]; then
	    return 1
	fi

	cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("$MYSQL_ROOT_PASSWORD") WHERE user='root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("") WHERE user='root' AND host='localhost';
EOF

	if [ "$MYSQL_DATABASE" != "" ]; then
	    echo "[i] Creating database: $MYSQL_DATABASE"
	    echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

	    if [ "$MYSQL_USER" != "" ]; then
		echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
		echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
	    fi
	fi

	/usr/bin/mysqld --user=mysql --bootstrap --verbose=0 < $tfile
	rm -f $tfile
fi

# execute any pre-exec scripts, useful for images
# based on this image
for i in /scripts/pre-exec.d/*sh
do
	if [ -e "${i}" ]; then
		echo "[i] pre-exec.d - processing $i"
		. ${i}
	fi
done

/usr/bin/mysqld --user=mysql --console --log-bin-trust-function-creators &




mkdir /Booster2
mkdir /Booster2/sql-gen

cp /booster2/Booster2/sql-gen/standardStuff.sql /Booster2/sql-gen


echo "Booster file: $1"
java -jar /sunshine/sunshine.jar transform -n "Generate SQL" -p /files/ -l /booster2/Booster2/ -i $1


SQL_FILE_NAME=`basename $1 boo2`generated.sql

mysql -u root < /files/$SQL_FILE_NAME

DB_NAME=$(grep -i "^create database" /files/$SQL_FILE_NAME | grep -o "\`[^\`]*\`" | tr -d '`')

mkdir /usr/local/tomcat/webapps/${DB_NAME} 

unzip -d /usr/local/tomcat/webapps/${DB_NAME} /booster2/gwi.war

sed -i "s-<dbname>IPG</dbname>-<dbname>${DB_NAME}</dbname>-g" /usr/local/tomcat/webapps/${DB_NAME}/WEB-INF/dbConfig.xml 

sed -i "s-> James Welch <-> ${DB_NAME} User<-g" /usr/local/tomcat/webapps/${DB_NAME}/index.html

sed -i "s-gwi-${DB_NAME}-g" /usr/local/tomcat/webapps/${DB_NAME}/js/script.js

rm -rf /usr/local/tomcat/webapps/ROOT

ls -s /usr/local/tomcat/webapps/ROOT /usr/local/tomcat/webapps/booster

for f in /files/sql-import/*.sql
do
  echo "Processing file $f..."
  mysql -u root < $f
done

#use booster to generate a triple map
echo "generating triple map: $1"
java -jar /sunshine/sunshine.jar transform -n "Generate Triple Map" -p /files/ -l /booster2/Booster2/ -i $1

#set up the dbname for the d2rq server
sed -i "s-jdbc:mysql://localhost:3306/IPG-jdbc:mysql://localhost:3306/${DB_NAME}-g" /usr/local/tomcat/webapps/d2rq/WEB-INF/web.xml 

#set the url/localport in the same file, as needed
sed -i "s-http://localhost:8081/d2rq/-http://localhost:80/d2rq/-g" /usr/local/tomcat/webapps/d2rq/WEB-INF/web.xml 

# copy the generated mapping file to D2RQ's web-inf dir
cp /files/`basename $1 boo2`mapping.ttl /usr/local/tomcat/webapps/d2rq/WEB-INF/mapping.ttl

#datadump for rdfunit 
TTL_FILE_NAME=`basename $1 boo2`datadump.ttl
cd /d2rq/d2rq/
chmod a+x dump-rdf 
#put a data dump in /files too, incase the users want it
bash ./dump-rdf -j jdbc:mysql://localhost:3306/${DB_NAME} -u root -p "" -o /files/${TTL_FILE_NAME} -f TURTLE -b file:/${TTL_FILE_NAME}/ /usr/local/tomcat/webapps/d2rq/WEB-INF/mapping.ttl

bash ./dump-rdf -j jdbc:mysql://localhost:3306/${DB_NAME} -u root -p "" -o /usr/local/tomcat/webapps/d2rq/data.n3 -b file:/data.n3/ /usr/local/tomcat/webapps/d2rq/WEB-INF/mapping.ttl


echo Starting Tomcat service...
bash /usr/local/tomcat/bin/catalina.sh run > /dev/null &
echo Tomcat service started.

sleep 10 && tail -f /usr/local/tomcat/logs/catalina.*.log



