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


#for entry in /boosterfiles/*
#do
  echo Booster file: $1
  java -jar /sunshine/sunshine.jar transform -n "Generate SQL" -p /boosterfiles/ -l /booster2/Booster2/ -i $1
#done

SQL_FILE_NAME=`basename $1 boo2`generated.sql

mysql -u root < /boosterfiles/$SQL_FILE_NAME

DB_NAME=$(grep -i "^ create database" /boosterfiles/$SQL_FILE_NAME | grep -o "\`[^\`]*\`" | tr -d '`')

sed -i "s-<dbname>Test</dbname>-<dbname>${DB_NAME}</dbname>-g" /usr/local/tomcat/webapps/gwi/WEB-INF/dbConfig.xml 


cd /d2rq/d2rq-0.8.1/

chmod a+x generate-mapping d2r-server

bash ./generate-mapping -o /usr/local/tomcat/webapps/d2rq/WEB-INF/mapping.ttl -d com.mysql.jdbc.Driver -u root -p "" jdbc:mysql://localhost:3306/$DB_NAME

cd /d2rq/

sed -i '/^@prefix jdbc: <http:\/\/d2rq.org\/terms\/jdbc\/> ./r d2r-server.conf' /usr/local/tomcat/webapps/d2rq/WEB-INF/mapping.ttl

echo Starting Tomcat service...
exec /usr/local/tomcat/bin/catalina.sh run &
echo Tomcat service started.

sh -c "while true; do sleep 1000; done"




