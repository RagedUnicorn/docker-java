FROM alpine:3.6

LABEL com.ragedunicorn.maintainer="Michael Wiesendanger <michael.wiesendanger@gmail.com>" \
  com.ragedunicorn.version="1.0"

#        _____ _    _____
#       / /   | |  / /   |
#  __  / / /| | | / / /| |
# / /_/ / ___ | |/ / ___ |
# \____/_/  |_|___/_/  |_|

# software versions
ENV \
  JAVA_VERSION=8.131.11-r2

ENV \
  JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/jre \
  PATH=$PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

RUN \
  set -ex; \
  apk add --no-cache openjdk8="${JAVA_VERSION}"

CMD ["/bin/sh"]
