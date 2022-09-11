#!/bin/bash

PORT=10880
SSH_PORT=10022
POD_NAME="gogs"
GOGS_VOLUME="${POD_NAME}-data"
NETWORK="development"
POSTGRES_POD_NAME="postgres"

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

if checkFlag "--ssh-port"; then
	SSH_PORT=GetArg "--ssh--port" $@
fi

if checkFlag "--port"; then
	PORT=GetArg "--port" $@
fi

if checkFlag "--db-pod-name"; then
	POSTGRES_POD_NAME=GetArg "--db-pod-name" $@
fi


#Pull Current Stable Gogs image
echo "Pulling Gogs"
docker pull gogs/gogs

#Check if the Volume is being used
count="$(docker ps -a --filter volume=${GOGS_VOLUME} | wc -l)"
if [ "$count" -gt 1 ]; then
  echo  -e "\e[1;31m Volume ${GOGS_VOLUME} in use. \e[0m"
  echo  -e "\e[1;31m Please clean up the container and volume first. \e[0m"
  exit 1
fi

#Check if Gogs volume exist
echo "Creating new volume if it doesn't exist."
data="$(sudo docker volume ls | grep "${GOGS_VOLUME}")"
if [ ! -z "$data" ]; then 
  echo "Found exitsing Volume: ${GOGS_VOLUME}"
  echo "Removing Volume: ${GOGS_VOLUME}"
  docker volume rm -f ${GOGS_VOLUME}
  echo "Created Volume: ${GOGS_VOLUME}"
  docker volume create ${GOGS_VOLUME}
else 
  echo "Created Volume: ${GOGS_VOLUME}"
  docker volume create ${GOGS_VOLUME}
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

#Check if dependancy Container is running
count="$(docker ps -a --filter name=${POSTGRES_POD_NAME} | wc -l)"
if [ "$count" -eq 1 ]; then
  echo  -e "\e[1;31m Dependancy container not running: ${POSTGRES_POD_NAME} \e[0m"
  exit 1
fi

#Check if Container is running
count="$(docker ps -a --filter name=${POD_NAME} | wc -l)"
if [ "$count" -gt 1 ]; then
  echo  -e "\e[1;31m Container already running under: ${POD_NAME} \e[0m"
  exit 1
fi

#Start the docker container
echo "Starting the Container..."
docker run -itd --network ${NETWORK} -p ${PORT}:3000 -p ${SSH_PORT}:22 -v ${GOGS_VOLUME}:/data --name ${POD_NAME} -e VIRTUAL_HOST=${POD_NAME} -e VIRTUAL_PORT=3000 gogs/gogs

echo "Wait for Gogs to start"
sleep 20

echo "Browser to http://127.0.0.1:${PORT}/ to finish setting up Gogs"
