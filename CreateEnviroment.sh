#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
POSTGRES_POD_NAME="postgres"
GOGS_POD_NAME="gogs"
REDMINE_POD_NAME="redmine"
JENKINS_POD_NAME="jenkins"
NETWORK="development"
GOGS_USERNAME="Gogs"
GOGS_PASSWORD="GogsPassword"
GOGS_DATABASE="GOGS"
GOGS_PORT=10880
REDMINE_USERNAME="redmine"
REDMINE_PASSWORD="RedminePassword"
REDMINE_DATABASE="redmine"
REDMINE_PORT=10882
JENKINS_PORT=10881

#Create Postgres
${SCRIPT_DIR}/CreateDockerPostgresql.sh --network ${NETWORK} --pod-name ${POSTGRES_POD_NAME}

#Wait for Postgres to finish starting
echo "Waiting on Postgres to finsih starting up"
sleep 15

#Setup the User and DB for Gogs and Redmine
echo "Creating Gogs user"
docker exec ${POSTGRES_POD_NAME} psql -U Admin -c "create user ${GOGS_USERNAME} password '${GOGS_PASSWORD}'" 

echo "Create Redmine User"
docker exec ${POSTGRES_POD_NAME} psql -U Admin -c "create user ${REDMINE_USERNAME} password '${REDMINE_PASSWORD}'" 

echo "Creating Gogs DB"
docker exec ${POSTGRES_POD_NAME} psql -U Admin -c "CREATE DATABASE ${GOGS_DATABASE} OWNER ${GOGS_USERNAME}"

echo "Creating Redmine DB"
docker exec ${POSTGRES_POD_NAME} psql -U Admin -c "CREATE DATABASE ${REDMINE_DATABASE} OWNER ${REDMINE_USERNAME}"

#Create Gogs
${SCRIPT_DIR}/CreateDockerGogs.sh --network ${NETWORK} --pod-name ${GOGS_POD_NAME} --db-pod-name ${POSTGRES_POD_NAME} --port "${GOGS_PORT}"

#Create Redmine
${SCRIPT_DIR}/CreateDockerRedmine.sh --network ${NETWORK} --pod-name ${REDMINE_POD_NAME} --db-pod-name ${POSTGRES_POD_NAME} --db-username ${REDMINE_USERNAME} --db-password ${REDMINE_PASSWORD} --port "${REDMINE_PORT}"

#Create Jenkins
${SCRIPT_DIR}/CreateDockerJenkins.sh --network ${NETWORK} --pod-name ${JENKINS_POD_NAME}

echo "################################################################################"
echo "################################################################################"
echo "################################################################################"
echo "Manual setup information:"
echo "################################################################################"
echo "  Gogs setup Info:"
echo "    DB Type: PostgreSQL"
echo "    Postgres DB connection name: ${POSTGRES_POD_NAME}:5432"
echo "    Postgres DB username: ${GOGS_USERNAME}"
echo "    Postgres DB Password: ${GOGS_PASSWORD}"
echo "    Gogs DB name: ${GOGS_DATABASE}"
echo "    Gogs Connection URL: http://127.0.0.1:${GOGS_PORT}"
echo ""
echo "  Redmine setup Info:"
echo "    Admin username: admin"
echo "    Admin password: admin"
echo "    Redmine Connection URL: http://127.0.0.1:${REDMINE_PORT}"
echo ""
echo "  Jenkins setup Info:"
echo "    Jenkins Admin password: $(docker exec jenkins cat "/var/jenkins_home/secrets/initialAdminPassword")"
echo "    Jenkins Connection URL: http://127.0.0.1:${JENKINS_PORT}"










