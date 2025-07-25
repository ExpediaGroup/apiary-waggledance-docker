#!/bin/bash
# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

WAGGLE_DANCE_HOME=/opt/waggle-dance

[[ ! -z $SERVER_YAML ]] && echo $SERVER_YAML|base64 -d > ${WAGGLE_DANCE_HOME}/conf/waggle-dance-server.yml

[[ ! -z $FEDERATION_YAML ]] && echo $FEDERATION_YAML|base64 -d > ${WAGGLE_DANCE_HOME}/conf/waggle-dance-federation.yml

#auto configure heapsize
if [ ! -z ${ECS_CONTAINER_METADATA_URI} ]; then
    export MEM_LIMIT=$(wget -q -O - ${ECS_CONTAINER_METADATA_URI}/task|jq -r .Limits.Memory)
    export HEAPSIZE=$(expr $MEM_LIMIT \* 90 / 100)
fi
[[ -z $HEAPSIZE ]] && export HEAPSIZE=1024

if [[ -n $BASTION_SSH_KEY_ARN ]] ; then
  mkdir -p /root/.ssh
  touch /root/.ssh/known_hosts
  aws secretsmanager get-secret-value --secret-id ${BASTION_SSH_KEY_ARN}|jq .SecretString -r|jq .private_key -r| base64 -d > /root/.ssh/bastion_ssh
fi

source "${WAGGLE_DANCE_HOME}"/service/waggle-dance-core-latest-exec.conf

[[ -n $HIVE_SITE_XML ]] && echo $HIVE_SITE_XML|base64 -d > ${WAGGLE_DANCE_HOME}/jars/hive-site.xml

# Configure logging format based on environment variable
if [[ "${LOGGING_STRUCTURED_FORMAT_CONSOLE}" == "json" ]]; then
    export LOG4J_APPENDER="STDOUT-JSON"
    echo "Using JSON structured logging"
else
    export LOG4J_APPENDER="STDOUT-TEXT"
    echo "Using text pattern logging"
fi

if [[ "${LOG4J_DEBUG:-false}" == "true" ]]; then
    JAVA_OPTS="$JAVA_OPTS -Dlog4j2.debug=true"
    echo "Log4j2 debug mode enabled"
fi

if [[ -n $DD_PROFILING_ENABLED && "$DD_PROFILING_ENABLED" = "true" ]]; then
  # To enable the Datadog Java Agent, the following environment variables must be set at runtime:
  # DD_PROFILING_ENABLED=true
  # DD_SERVICE=service-name
  # DD_ENV=env-name
  # DD_VERSION=version
  export JAVA_OPTS="$JAVA_OPTS -javaagent:/opt/waggle-dance/jars/dd-java-agent.jar -XX:FlightRecorderOptions=stackdepth=256 -Ddd.profiling.enabled=${DD_PROFILING_ENABLED} -Ddd.service=${DD_SERVICE} -Ddd.env=${DD_ENV} -Ddd.version=${DD_VERSION}"
fi  

echo "=== Starting Waggle Dance ==="

exec java $JAVA_OPTS -jar "${WAGGLE_DANCE_HOME}"/service/waggle-dance-core-latest-exec.jar $RUN_ARGS
