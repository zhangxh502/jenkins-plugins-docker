#!/bin/sh
set -e

docker_daemon_file="/etc/docker/daemon.json"
dockerd_daemon=`which dockerd`
if [ -x $dockerd_daemon ]; then
	mkdir -p /etc/docker
	touch $docker_daemon_file

	if [ -n $CI_DOCKER_REGISTRY ] && [ "$CI_DOCKER_REGISTRY" != "" ]; then
		echo "{\"insecure-registries\": [\"$CI_DOCKER_REGISTRY\"]}" > $docker_daemon_file
	fi

	nohup $dockerd_daemon -g /var/lib/docker >/dev/null 2>&1 &
else
	echo "dockerd exec not found, please install!"
	exit 1
fi

while true
do
	sleep 5s
	if [ -e "/var/run/docker.sock" ];then
		break
	fi
done

docker_exec=`which docker`
if [ -x $docker_exec ]; then
	$docker_exec version
else
	echo "docker exec not found, please install!"
	exit 1
fi

if [ -n $CI_DOCKER_USERNAME ] && [ "$CI_DOCKER_USERNAME" != "" ] && [ -n $CI_DOCKER_PASSWORD ] && [ "$CI_DOCKER_PASSWORD" != "" ] && [ -n $CI_DOCKER_REGISTRY ] && [ "$CI_DOCKER_REGISTRY" != "" ]
then
	$docker_exec login -u $CI_DOCKER_USERNAME -p $CI_DOCKER_PASSWORD $CI_DOCKER_REGISTRY
	if [[ $? -ne 0 ]];then
		exit 3
	fi
fi

cd /home/jenkins/workspace/$CI_PIPELINE_NAME
$docker_exec build --rm=true -f $CI_DOCKERFILE -t 00000000 . --pull=true --label org.label-schema.build-date=$(date "+%Y-%m-%dT%H:%M:%SZ") --label org.label-schema.vcs-ref=00000000 --label org.label-schema.vcs-url=
if [[ $? -ne 0 ]];then
    exit 3
fi

$docker_exec  tag 00000000 $CI_DOCKER_REPO:$CI_DOCKER_TAG
if [[ $? -ne 0 ]];then
    exit 3
fi

$docker_exec push $CI_DOCKER_REPO:$CI_DOCKER_TAG
if [[ $? -ne 0 ]];then
    exit 3
fi

$docker_exec rmi 00000000
if [[ $? -ne 0 ]];then
    exit 3
fi

$docker_exec system prune -f
