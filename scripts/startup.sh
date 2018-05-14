#!/bin/bash
# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

WAGGLE_DANCE_HOME=/opt/waggle-dance

source "${WAGGLE_DANCE_HOME}"/service/waggle-dance-core-latest-exec.conf

exec java -jar "${WAGGLE_DANCE_HOME}"/service/waggle-dance-core-latest-exec.jar  $JAVA_OPTS $RUN_ARGS
