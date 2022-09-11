FROM tomcat:9.0

COPY --chown=root:root tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml

RUN cp -r /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps/

COPY --chown=root:root context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml
