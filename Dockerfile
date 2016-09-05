# Booster2 Docker install
FROM tomcat:8.5-alpine
MAINTAINER James Welch <jamesrwelch@gmail.com>
EXPOSE 8080

VOLUME /boosterfiles


ADD gwi.war /usr/local/tomcat/webapps
ADD Booster2.zip /booster2/
ADD sunshine.jar /sunshine/

RUN unzip -d /booster2 /booster2/Booster2.zip 

RUN apk --update add mysql mysql-client pwgen

ADD startup.sh /scripts/startup.sh



RUN mkdir /scripts/pre-exec.d && \
mkdir /scripts/pre-init.d && \
chmod -R 755 /scripts



EXPOSE 3306

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/scripts/startup.sh"]