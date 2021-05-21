# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

FROM amazonlinux:latest

ARG JAVA_VERSION=1.8.0
ARG WAGGLE_DANCE_VERSION=3.9.4
ARG APIARY_EXTENSIONS_VERSION=7.2.0

ENV WAGGLE_DANCE_HOME /opt/waggle-dance

RUN yum -y update && \
  yum install -y java-${JAVA_VERSION}-openjdk \
    procps \
    awscli \
    wget \
    util-linux \
    jq \
    https://repo1.maven.org/maven2/com/hotels/waggle-dance-rpm/${WAGGLE_DANCE_VERSION}/waggle-dance-rpm-${WAGGLE_DANCE_VERSION}.rpm \
  && yum clean all \
  && rm -rf /var/cache/yum

ADD https://repo1.maven.org/maven2/com/expediagroup/apiary/hive-hooks/${APIARY_EXTENSIONS_VERSION}/hive-hooks-${APIARY_EXTENSIONS_VERSION}.jar "${WAGGLE_DANCE_HOME}"/jars/

COPY files/waggle-dance-server.yml "${WAGGLE_DANCE_HOME}"/conf/
COPY files/waggle-dance-federation.yml "${WAGGLE_DANCE_HOME}"/conf/
COPY files/waggle-dance-core-latest-exec.conf "${WAGGLE_DANCE_HOME}"/service/
COPY scripts/startup.sh "${WAGGLE_DANCE_HOME}"

ENTRYPOINT ["/bin/sh", "-c", "exec ${WAGGLE_DANCE_HOME}/startup.sh"]

EXPOSE 48869
