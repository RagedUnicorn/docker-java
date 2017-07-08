#!/bin/bash
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description build script for docker-java container

# abort when trying to use unset variable
set -o nounset

# variable setup
DOCKER_JAVA_TAG="ragedunicorn/java"
DOCKER_JAVA_NAME="java"

# get absolute path to script and change context to script folder
SCRIPTPATH="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
cd "${SCRIPTPATH}"

echo "$(date) [INFO]: Building container: ${DOCKER_JAVA_NAME} - ${DOCKER_JAVA_TAG}"

# build java container
docker build -t "${DOCKER_JAVA_TAG}" ../
