# Booster2 Docker install
FROM tomcat:8.5-alpine
MAINTAINER James Welch <jamesrwelch@gmail.com>
EXPOSE 8080 3306

VOLUME /files


ADD gwi.war /booster2/
ADD Booster2.zip /booster2/
ADD sunshine.jar /sunshine/
ADD d2rq.war /d2rq/
ADD d2rq.zip /d2rq/
ADD d3sparql-graph.zip /d3sparql-graph/
ADD rdfunit.war /rdfunit/
ADD web.war /booster2/

RUN unzip -d /booster2 /booster2/Booster2.zip 
RUN unzip -d /d2rq /d2rq/d2rq.zip 
RUN mkdir /usr/local/tomcat/webapps/gwi && unzip -d /usr/local/tomcat/webapps/gwi /booster2/gwi.war
RUN mkdir /usr/local/tomcat/webapps/booster && unzip -o -d /usr/local/tomcat/webapps/booster /booster2/web.war
RUN mkdir /usr/local/tomcat/webapps/d2rq && unzip -o -d /usr/local/tomcat/webapps/d2rq /d2rq/d2rq.war
RUN mkdir /usr/local/tomcat/webapps/d3sparql-graph && unzip -o -d /usr/local/tomcat/webapps/d3sparql-graph /d3sparql-graph/d3sparql-graph.zip
RUN mkdir /usr/local/tomcat/webapps/rdfunit && unzip -o -d /usr/local/tomcat/webapps/rdfunit /rdfunit/rdfunit.war

RUN apk --update add mysql mysql-client bash

ADD startup.sh /scripts/startup.sh
ADD booster-deploy.sh /booster2/booster-deploy.sh


RUN mkdir /scripts/pre-exec.d && \
mkdir /scripts/pre-init.d && \
chmod -R 755 /scripts && \
chmod -R 755 /booster2


EXPOSE 3306

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/scripts/startup.sh"]
