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

exec java $JAVA_OPTS -jar "${WAGGLE_DANCE_HOME}"/service/waggle-dance-core-latest-exec.jar $RUN_ARGS
