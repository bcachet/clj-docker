#!/bin/sh
set -e

exec java ${JAVA_AGENT_OPTS} ${JAVA_OPTS} -cp /app.jar clojure.main -m exo.main "$@"