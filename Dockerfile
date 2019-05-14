FROM rancher/jenkins-plugins-docker:17.12

COPY ./docker-start.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/docker-start.sh
