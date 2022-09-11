#!/bin/bash

POSTGRES_USERNAME="Admin"
POSTGRES_PASSWORD="AdminPassword"
PORT=15432
POSTGRES_VERSION="14.5"
POD_NAME="postgres"
POSTGRES_VOLUME="${POD_NAME}-data"
NETWORK="development"

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

if checkFlag "--version"; then
	POSTGRES_VERSION=GetArg "--version" $@
fi

if checkFlag "--port"; then
	PORT=GetArg "--port" $@
fi


#Pull Current Stable Postgres image
echo "Pulling postgres:${POSTGRES_VERSION}"
docker pull postgres:${POSTGRES_VERSION}

#Check if the Volume is being used
count="$(docker ps -a --filter volume=${POSTGRES_VOLUME} | wc -l)"
if [ "$count" -gt 1 ]; then
  echo  -e "\e[1;31m Volume ${POSTGRES_VOLUME} in use. \e[0m"
  echo  -e "\e[1;31m Please clean up the container and volume first. \e[0m"
  exit 1
fi

#Check if Postgresql volume exist
echo "Creating new volume if it doesn't exist."
data="$(sudo docker volume ls | grep "${POSTGRES_VOLUME}")"
if [ ! -z "$data" ]; then 
  echo "Found exitsing Volume: ${POSTGRES_VOLUME}"
  echo "Removing Volume: ${POSTGRES_VOLUME}"
  docker volume rm -f ${POSTGRES_VOLUME}
  echo "Created Volume: ${POSTGRES_VOLUME}"
  docker volume create ${POSTGRES_VOLUME}
else 
  echo "Created Volume: ${POSTGRES_VOLUME}"
  docker volume create ${POSTGRES_VOLUME}
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

#Start the docker container
echo "Starting the Container..."
docker run -itd --network ${NETWORK} -e POSTGRES_USER=${POSTGRES_USERNAME} -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} -p ${PORT}:5432 -v ${POSTGRES_VOLUME}:/var/lib/postgresql/data --name ${POD_NAME} postgres:${POSTGRES_VERSION}

#Show running container details
docker ps -a --filter name=${POD_NAME}

