# Release

> This document explains how a new release is created for this docker container

* Update jre docker-compose files
  * Update .env image tag version
* Update jdk docker-compose files
  * Update docker-compose.dev.yml image to new version
  * Update docker-compose.yml image to new version
* Create a new git tag and push it
  * `git tag vx.x.x`
  * `git push origin --tags`
* Draft new Github release with description
  * Title should be the version e.g. vx.x.x
  * Short description of what was added newly
* Update jre docker hub
  * Build dev tag `docker-compose -f docker-compose.dev.yml build`
  * Push image to dockerhub `docker push ragedunicorn/openjdk:x.x.x-jre-dev`
  * Build stable tag `docker-compose build`
  * Push image to dockerhub `docker push ragedunicorn/openjdk:x.x.x-jre-stable`
* Update jdk docker hub
  * Build dev tag `docker-compose -f docker-compose.dev.yml build`
  * Push image to dockerhub `docker push ragedunicorn/openjdk:x.x.x-jdk-dev`
  * Build stable tag `docker-compose build`
  * Push image to dockerhub `docker push ragedunicorn/openjdk:x.x.x-jdk-stable`
* Update docker hub description links
