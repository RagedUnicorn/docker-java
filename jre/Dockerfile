FROM alpine:3.12.0

LABEL com.ragedunicorn.maintainer="Michael Wiesendanger <michael.wiesendanger@gmail.com>"

#      ____                       ______  __ __
#     / __ \____  ___  ____      / / __ \/ //_/
#   / / / / __ \/ _ \/ __ \__  / / / / / ,<
#  / /_/ / /_/ /  __/ / / / /_/ / /_/ / /| |
#  \____/ .___/\___/_/ /_/\____/_____/_/ |_|
#       /_/

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# software versions
ENV \
  JAVA_VERSION=11.0.7_p10-r1

ENV \
  JAVA_HOME=/usr/lib/jvm/java-11-openjdk/jre \
  PATH=$PATH:/usr/lib/jvm/java-11-openjdk/jre/bin:/usr/lib/jvm/java-11-openjdk/bin

RUN \
  set -ex && \
  apk add --no-cache openjdk11-jre="${JAVA_VERSION}"

ENTRYPOINT ["/bin/sh"]
