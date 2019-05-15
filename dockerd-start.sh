#!/bin/sh
set -e

dockerd_daemon=`which dockerd`
if [ -x $dockerd_daemon ]; then
	mkdir -p /etc/docker
	touch /etc/docker/daemon.json
	echo "{\"insecure-registries\": [\"$DOCKER_REGISTRY\"]}" > /etc/docker/daemon.json
	nohup $dockerd_daemon -H fd:// --config-file /etc/docker/daemon.json >/dev/null 2>&1 &
else
	echo "dockerd exec not found, please install!"
	exit 1
fi

docker_exec=`which docker`
if [ -x $docker_exec ]; then
	$docker_exec version
else
	echo "docker exec not found, please install!"
	exit 1
fi

if [ -z $DOCKER_USERNAME] && [ -z $DOCKER_PASSWORD]
then
	$docker_exec login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $DOCKER_REGISTRY
	if [[ $? -ne 0 ]];then
		exit 3
	fi
fi

cd /home/jenkins/workspace/$CICD_EXECUTION_ID
$docker_exec build --rm=true -f $PLUGIN_DOCKERFILE -t 00000000 . --pull=true --label org.label-schema.build-date=$(date "+%Y-%m-%dT%H:%M:%SZ") --label org.label-schema.vcs-ref=00000000 --label org.label-schema.vcs-url=
if [[ $? -ne 0 ]];then
    exit 3
fi

$docker_exec  tag 00000000 $PLUGIN_REPO:$PLUGIN_TAG
if [[ $? -ne 0 ]];then
    exit 3
fi

$docker_exec push $PLUGIN_REPO:$PLUGIN_TAG
if [[ $? -ne 0 ]];then
    exit 3
fi

$docker_exec rmi 00000000
if [[ $? -ne 0 ]];then
    exit 3
fi

$docker_exec system prune -f
