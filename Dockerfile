# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

From amazonlinux:latest

ENV JAVA_VERSION 1.8.0
ENV WAGGLE_DANCE_VERSION 2.4.2
ENV WAGGLE_DANCE_HOME /opt/waggle-dance

RUN yum -y update && \
  yum install -y java-${JAVA_VERSION}-openjdk \
    procps \
    procps \
    util-linux \
    http://search.maven.org/remotecontent?filepath=com/hotels/waggle-dance-rpm/"${WAGGLE_DANCE_VERSION}"/waggle-dance-rpm-"${WAGGLE_DANCE_VERSION}".rpm && \
  yum clean all

COPY files/waggle-dance-server.yml "${WAGGLE_DANCE_HOME}"/conf/
COPY files/waggle-dance-federation.yml "${WAGGLE_DANCE_HOME}"/conf/
COPY files/waggle-dance-core-latest-exec.conf "${WAGGLE_DANCE_HOME}"/service/
COPY scripts/startup.sh "${WAGGLE_DANCE_HOME}"

ENTRYPOINT ["/bin/sh", "-c", "exec ${WAGGLE_DANCE_HOME}/startup.sh"]

EXPOSE 48869
