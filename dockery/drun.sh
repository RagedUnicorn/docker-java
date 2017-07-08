#!/bin/bash
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description run script for docker-java container

# abort when trying to use unset variable
set -o nounset

# variable setup
DOCKER_JAVA_TAG="ragedunicorn/java"
DOCKER_JAVA_NAME="java"
DOCKER_JAVA_ID=0

# get absolute path to script and change context to script folder
SCRIPTPATH="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
cd "${SCRIPTPATH}"

# check if there is already an image created
docker inspect ${DOCKER_JAVA_NAME} &> /dev/null

if [ $? -eq 0 ]; then
  # start container
  docker start "${DOCKER_JAVA_NAME}"
else
  ## run image:
  # -d run in detached mode
  # -i Keep STDIN open even if not attached
  # -t Allocate a pseudo-tty
  # --name define a name for the container(optional)
  DOCKER_JAVA_ID=$(docker run \
  -dit \
  --name "${DOCKER_JAVA_NAME}" "${DOCKER_JAVA_TAG}")
fi

if [ $? -eq 0 ]; then
  # print some info about containers
  echo "$(date) [INFO]: Container info:"
  docker inspect -f '{{ .Config.Hostname }} {{ .Name }} {{ .Config.Image }} {{ .NetworkSettings.IPAddress }}' ${DOCKER_JAVA_NAME}
else
  echo "$(date) [ERROR]: Failed to start container - ${DOCKER_JAVA_NAME}"
fi
