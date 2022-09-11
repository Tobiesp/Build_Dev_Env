#!/bin/bash

POSTGRES_VOLUME="postgres-data"
POSTGRES_POD_NAME="Postgresql"

#Check if the Volume is being used
count=$(docker volume ls --filter name=${POSTGRES_VOLUME} | wc -l)
if [ "$count" -eq 1 ]; then
  echo  -e "\e[1;31m Volume ${POSTGRES_VOLUME} does not exist. \e[0m"
  exit 1
fi

#Check if Container is running
count=$(docker ps -a --filter name=${POSTGRES_POD_NAME} | wc -l)
if [ "$count" -gt 1 ]; then
  echo  -e "\e[1;31m Container already running: ${POSTGRES_POD_NAME} \e[0m"
  docker ps -a --filter name=${POSTGRES_POD_NAME}
  exit 1
fi

docker start ${POSTGRES_POD_NAME}
