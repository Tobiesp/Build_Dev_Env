#!/bin/bash

PORT=10881
PORT_2=50000
POD_NAME="jenkins"
JENKINS_DRIVE_VOLUME="${POD_NAME}-data"
JENKINS_CERT_VOLUME="${POD_NAME}-docker-certs"
NETWORK="development"
JENKINS_IMAGE="jenkins/jenkins"

function GetArg() {
  local arg="${1}"
  shift
  local currentArg="${1}"
  while [ "${arg}" != "${currentArg}" ]; do
  	shift
  	shift
  	local currentArg="${1}"
  	if [ -z $currentArg ]; then
  		break
		fi
	done
	if [ "${arg}" = "${currentArg}" ]; then
		shift 
		echo "${1}"
		return 0
	fi
}

function checkFlag() {
	local arg="${1}"
  shift
  local currentArg="${1}"
  while [ "${arg}" != "${currentArg}" ]; do
  	shift
  	currentArg="${1}"
  	if [ -z $currentArg ]; then
  		break
		fi
	done
	if [ "${arg}" = "${currentArg}" ]; then
		return 0
	fi
	return 1
}

if checkFlag "--network"; then
	NETWORK=GetArg "--network" $@
fi

if checkFlag "--pod-name"; then
	POD_NAME=GetArg "--pod-name" $@
fi

if checkFlag "--node-port"; then
	PORT_2=GetArg "--node-port" $@
fi

if checkFlag "--port"; then
	PORT=GetArg "--port" $@
fi


#Pull Current Stable Gogs image
echo "Pulling Jenkins"
docker pull jenkins/jenkins

if [ -f "Jenkins.Dockerfile" ]; then
	docker build -f Jenkins.Dockerfile -t jenkins-mvn .
	if [ "$?" -eq 0 ]; then
		JENKINS_IMAGE="jenkins-mvn"
	fi
fi

#Check if the Volume is being used
count="$(docker ps -a --filter volume=${JENKINS_DRIVE_VOLUME} | wc -l)"
if [ "$count" -gt 1 ]; then
  echo  -e "\e[1;31m Volume ${JENKINS_DRIVE_VOLUME} in use. \e[0m"
  echo  -e "\e[1;31m Please clean up the container and volume first. \e[0m"
  exit 1
fi

#Check if the Volume is being used
count="$(docker ps -a --filter volume=${JENKINS_CERT_VOLUME} | wc -l)"
if [ "$count" -gt 1 ]; then
  echo  -e "\e[1;31m Volume ${JENKINS_CERT_VOLUME} in use. \e[0m"
  echo  -e "\e[1;31m Please clean up the container and volume first. \e[0m"
  exit 1
fi

#Check if the volume exist
echo "Creating new volume if it doesn't exist: ${JENKINS_DRIVE_VOLUME}"
data="$(sudo docker volume ls | grep "${JENKINS_DRIVE_VOLUME}")"
if [ ! -z "$data" ]; then 
  echo "Found exitsing Volume: ${JENKINS_DRIVE_VOLUME}"
  echo "Removing Volume: ${JENKINS_DRIVE_VOLUME}"
  docker volume rm -f ${JENKINS_DRIVE_VOLUME}
  echo "Created Volume: ${JENKINS_DRIVE_VOLUME}"
  docker volume create ${JENKINS_DRIVE_VOLUME}
else 
  echo "Created Volume: ${JENKINS_DRIVE_VOLUME}"
  docker volume create ${JENKINS_DRIVE_VOLUME}
fi

#Check if the volume exist
echo "Creating new volume if it doesn't exist: ${JENKINS_CERT_VOLUME}"
data="$(sudo docker volume ls | grep "${JENKINS_CERT_VOLUME}")"
if [ ! -z "$data" ]; then 
  echo "Found exitsing Volume: ${JENKINS_CERT_VOLUME}"
  echo "Removing Volume: ${JENKINS_CERT_VOLUME}"
  docker volume rm -f ${JENKINS_CERT_VOLUME}
  echo "Created Volume: ${JENKINS_CERT_VOLUME}"
  docker volume create ${JENKINS_CERT_VOLUME}
else 
  echo "Created Volume: ${JENKINS_CERT_VOLUME}"
  docker volume create ${JENKINS_CERT_VOLUME}
fi

#Check if network is created
echo "Creating new network if it doesn't exist: ${NETWORK}"
data="$(sudo docker network ls | grep "${NETWORK}")"
if [ ! -z "$data" ]; then 
  echo "Found exitsing Network: ${NETWORK}"
else 
  echo "Created Network: ${NETWORK}"
  docker network create ${NETWORK}
fi

#Check if Container is running
count="$(docker ps -a --filter name=${POD_NAME} | wc -l)"
if [ "$count" -gt 1 ]; then
  echo  -e "\e[1;31m Container already running under: ${POD_NAME} \e[0m"
  exit 1
fi

#Check if Container is running
count="$(docker ps -a --filter name=${GOGS_POD_NAME} | wc -l)"
if [ "$count" -eq 1 ]; then
  echo  -e "\e[1;31m Container not running: ${GOGS_POD_NAME} \e[0m"
  exit 1
fi

#Start the docker container
echo "Starting the Container..."

docker run --name ${POD_NAME} --restart=on-failure --detach --network ${NETWORK} --env DOCKER_HOST=tcp://docker:2376 --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 --publish ${PORT}:8080 --publish ${PORT_2}:50000 --volume ${JENKINS_DRIVE_VOLUME}:/var/jenkins_home --volume ${JENKINS_CERT_VOLUME}:/certs/client:ro ${JENKINS_IMAGE}

echo "Wait for Jenkins to start"
sleep 20

echo "Browser to http://127.0.0.1:${PORT}/ to finish setting up Jenkins"
