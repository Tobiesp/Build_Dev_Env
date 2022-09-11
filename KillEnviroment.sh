#!/bin/bash

POSTGRES_POD_NAME="postgres"
GOGS_POD_NAME="gogs"
REDMINE_POD_NAME="redmine"
JENKINS_POD_NAME="jenkins"

function getPodData() {
	local pod_name_v="${1}"
	local data_v="$(docker ps -a --filter name=${pod_name_v} --format "{{.Names}} {{.Mounts}} {{.Networks}}")"
	if [ -z "$data_v" ]; then
		data_v="$(docker container ls -a --filter name=${pod_name_v} --format "{{.Names}} {{.Mounts}} {{.Networks}}")"
	fi
	echo "${data_v}"
}

function getAllMounts() {
  local data_v="${1}"
  if [ ! -z "$data_v" ]; then
		local mount_v="$(echo "$data_v" | cut --delimiter=\  -f 2)"
		IFS=', ' read -r -a array <<< "${mount_v}"
		echo ${array[@]}
	fi
}

function deleteMount() {
  local pod_name_v="${1}"
	local mount_v="${2}"
	if [ -z "$mount_v" ]; then
		return 1
	fi
	if [[ $mount_v =~ .*… ]]; then
		mount_v="$(echo "$mount_v" | cut -d… -f 1)"
	fi
	local data_v="$(docker volume ls | grep ${mount_v})"
	if [ -z "$data_v" ]; then
		echo "Volume for ${pod_name_v} not found: ${mount_v}"
	else
		data_v="$(echo "$data_v" | cut --delimiter=\  -f 6)"
		echo "Removing volume for ${pod_name_v}: ${data_v}"
		docker volume rm ${data_v}
	fi
}

function deleteAllMounts() {
  local pod_name_v="${1}"
	local data_v="${2}"
	if [ -z "$data_v" ]; then
		return 1
	fi
	for mount in $(getAllMounts "${data_v}"); do
		deleteMount "${pod_name_v}" "${mount}"
	done
}

function deleteAllNetworks() {
  local pod_name_v="${1}"
	local networks_v="${2}"
	if [ -z "${networks_v}" ]; then
		return 1
	fi
	echo "All networks for "${pod_name_v}": ${networks_v}"
	IFS=', ' read -r -a array <<< "${networks_v}"
	for network in ${array[@]}; do
		deleteNetwork "${pod_name_v}" "${network}"
	done
}

function deleteNetwork() {
  local pod_name_v="${1}"
	local network_v="${2}"
	if [[ $network_v =~ .*… ]]; then
		network_v="$(echo "$network_v" | cut -d… -f 1)"
	fi
	local data_v="$(docker network ls | grep ${network_v})"
	if [ -z "$data_v" ]; then
		echo "Network for ${pod_name_v} not found: ${network_v}"
	else
		data_v="$(echo "$data_v" | cut --delimiter=\  -f 4)"
		if [ "${data_v}" = "bridge" ]; then
			return 1
		elif [ "${data_v}" = "host" ]; then
			return 1
		elif [ "${data_v}" = "none" ]; then
			return 1
		else
			echo "Deleteing network for ${pod_name_v}: ${data_v}"
			docker network rm ${data_v}
		fi
	fi
}

function cleanUpPod() {
	local pod_name_v="${1}"
	local data_v="$(docker ps -a --filter name=${pod_name_v} --format "{{.Names}}")"
	if [ -z "$data_v" ]; then
		echo "${pod_name_v} not running."
		data_v="$(docker ps -a --filter name=${pod_name_v} --format "{{.Names}}")"
		if [ -z "$data_v" ]; then
			echo "Cleaning up pod: ${pod_name_v}"
			docker container rm ${pod_name_v}
		else
			echo "${pod_name_v} doesn't exist."
		fi
	else
		echo "Stopping pod: ${pod_name_v}"
		docker container stop ${pod_name_v}
		docker container wait ${pod_name_v}
		echo "Cleaning up pod: ${pod_name_v}"
		docker container rm ${pod_name_v}
	fi
}

# Get the specific docker data for Jenkins.
data="$(getPodData "${JENKINS_POD_NAME}")"
echo "Jenkins Data: ${data}"
cleanUpPod ${JENKINS_POD_NAME}

if [ ! -z "$data" ]; then
	deleteAllMounts "${JENKINS_POD_NAME}" "$data"
	JENKINS_NETWORK="$(echo "$data" | cut --delimiter=\  -f 3)"
	echo "Jenkins Network: ${JENKINS_NETWORK}"
fi

# Get the specific docker data for Redmine.
data="$(getPodData "${REDMINE_POD_NAME}")"
echo "Redmine Data: ${data}"
cleanUpPod ${REDMINE_POD_NAME}

if [ ! -z "$data" ]; then
	deleteAllMounts "${REDMINE_POD_NAME}" "$data"
	REDMINE_NETWORK="$(echo "$data" | cut --delimiter=\  -f 3)"
	echo "Redmine Network: ${REDMINE_NETWORK}"
fi

# Get the specific docker data for Gogs.
data="$(getPodData "${GOGS_POD_NAME}")"
echo "Gogs Data: ${data}"
cleanUpPod ${GOGS_POD_NAME}

if [ ! -z "$data" ]; then
	deleteAllMounts "${GOGS_POD_NAME}" "$data"
	GOGS_NETWORK="$(echo "$data" | cut --delimiter=\  -f 3)"
	echo "Gogs Network: ${GOGS_NETWORK}"
fi

# Get the specific docker data for Postgres.
data="$(getPodData "${POSTGRES_POD_NAME}")"
echo "Postgres Data: ${data}"
cleanUpPod ${POSTGRES_POD_NAME}

if [ ! -z "$data" ]; then
	deleteAllMounts "${POSTGRES_POD_NAME}" "$data"
	POSTGRES_NETWORK="$(echo "$data" | cut --delimiter=\  -f 3)"
	echo "Postgres Network: ${POSTGRES_NETWORK}"
fi

#Cleaning up the networks
echo "Cleaning up networks:"
deleteAllNetworks "${JENKINS_POD_NAME}" "${JENKINS_NETWORK}"
deleteAllNetworks "${REDMINE_POD_NAME}" "${REDMINE_NETWORK}"
deleteAllNetworks "${GOGS_POD_NAME}" "${GOGS_NETWORK}"
deleteAllNetworks "${POSTGRES_POD_NAME}" "${POSTGRES_NETWORK}"




