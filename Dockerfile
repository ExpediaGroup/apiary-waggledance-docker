# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

FROM amazonlinux:2023

ARG JAVA_VERSION=java-17-amazon-corretto
ARG WAGGLE_DANCE_VERSION=4.0.3
ARG APIARY_EXTENSIONS_VERSION=7.3.2
ARG DD_JAVA_AGENT_VERSION=1.51.2

ENV WAGGLE_DANCE_HOME=/opt/waggle-dance

RUN dnf install -y ${JAVA_VERSION} procps wget util-linux jq zip \
    https://repo1.maven.org/maven2/com/expediagroup/waggle-dance-rpm/${WAGGLE_DANCE_VERSION}/waggle-dance-rpm-${WAGGLE_DANCE_VERSION}.rpm \
  && dnf clean all \
  && rm -rf /var/cache/yum

RUN ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip ; \
  elif [ "$ARCH" = "aarch64" ]; then \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o /tmp/awscliv2.zip ; \
  else \
    echo "Unsupported architecture: $ARCH" && exit 1 ; \
  fi \
  && unzip /tmp/awscliv2.zip -d /tmp \
  && /tmp/aws/install -i /opt/aws-cli -b /usr/local/bin \
  && rm -rf /tmp/awscliv2.zip /tmp/aws  

ADD https://repo1.maven.org/maven2/com/expediagroup/apiary/hive-hooks/${APIARY_EXTENSIONS_VERSION}/hive-hooks-${APIARY_EXTENSIONS_VERSION}.jar "${WAGGLE_DANCE_HOME}"/jars/
ADD https://repo1.maven.org/maven2/com/datadoghq/dd-java-agent/${DD_JAVA_AGENT_VERSION}/dd-java-agent-${DD_JAVA_AGENT_VERSION}.jar "${WAGGLE_DANCE_HOME}"/jars/dd-java-agent.jar
ADD https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-layout-template-json/2.17.1/log4j-layout-template-json-2.17.1.jar /tmp

COPY files/waggle-dance-server.yml "${WAGGLE_DANCE_HOME}"/conf/
COPY files/waggle-dance-federation.yml "${WAGGLE_DANCE_HOME}"/conf/
COPY files/log4j2.yml "${WAGGLE_DANCE_HOME}"/conf/
COPY files/waggle-dance-core-latest-exec.conf "${WAGGLE_DANCE_HOME}"/service/
COPY scripts/startup.sh "${WAGGLE_DANCE_HOME}"

ENTRYPOINT ["/bin/sh", "-c", "exec ${WAGGLE_DANCE_HOME}/startup.sh"]

EXPOSE 48869
