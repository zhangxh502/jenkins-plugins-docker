#!/bin/sh
set -e

docker_daemon_file="/etc/docker/daemon.json"
dockerd_daemon=`which dockerd`
if [ -x $dockerd_daemon ]; then
	mkdir -p /etc/docker
	touch $docker_daemon_file
	echo "{\"insecure-registries\": [\"$DOCKER_REGISTRY\"]}" > $docker_daemon_file
	nohup $dockerd_daemon -g /var/lib/docker >/dev/null 2>&1 &
else
	echo "dockerd exec not found, please install!"
	exit 1
fi
