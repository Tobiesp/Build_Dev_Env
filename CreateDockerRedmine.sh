#!/bin/bash

PORT=10882
POD_NAME="redmine"
NETWORK="development"
POSTGRES_POD_NAME="postgres"
POSTGRES_USERNAME="redmine"
POSTGRES_PASSWORD="RedminePassword"
REDMINE_IMAGE="redmine"

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

if checkFlag "--port"; then
	PORT=GetArg "--port" $@
fi

if checkFlag "--db-pod-name"; then
	POSTGRES_POD_NAME=GetArg "--db-pod-name" $@
fi

if checkFlag "--db-username"; then
	POSTGRES_USERNAME=GetArg "--db-username" $@
fi

if checkFlag "--db-password"; then
	POSTGRES_PASSWORD=GetArg "--db-password" $@
fi

if [ -f "Redmine.Dockerfile" ]; then
	docker build -f Redmine.Dockerfile -t redmine-rp .
	if [ "$?" -eq 0 ]; then
		REDMINE_IMAGE="redmine-rp"
	fi
fi

#Pull Current Stable Gogs image
echo "Pulling Image"
docker pull redmine

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

docker run -d --name ${POD_NAME} --network ${NETWORK}  --publish ${PORT}:3000 -e REDMINE_DB_POSTGRES=${POSTGRES_POD_NAME} -e REDMINE_DB_USERNAME=${POSTGRES_USERNAME} -e REDMINE_DB_PASSWORD=${POSTGRES_PASSWORD} -e RAILS_RELATIVE_URL_ROOT='/redmine' redmine

echo "Wait for Redmine to start"
sleep 20

echo "Browser to http://127.0.0.1:${PORT}/ to finish setting up Redmine"

