#!/bin/bash
# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

WAGGLE_DANCE_HOME=/opt/waggle-dance

[[ ! -z $SERVER_YAML ]] && echo $SERVER_YAML|base64 -d > ${WAGGLE_DANCE_HOME}/conf/waggle-dance-server.yml

[[ ! -z $FEDERATION_YAML ]] && echo $FEDERATION_YAML|base64 -d > ${WAGGLE_DANCE_HOME}/conf/waggle-dance-federation.yml

[[ -z $HEAPSIZE ]] && export HEAPSIZE=1024

source "${WAGGLE_DANCE_HOME}"/service/waggle-dance-core-latest-exec.conf

exec java -jar "${WAGGLE_DANCE_HOME}"/service/waggle-dance-core-latest-exec.jar  $JAVA_OPTS $RUN_ARGS
