FROM rancher/jenkins-plugins-docker:17.12

COPY ./dockerd-start.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/dockerd-start.sh