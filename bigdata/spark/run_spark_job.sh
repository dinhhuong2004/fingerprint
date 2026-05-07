#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT_DIR"
docker compose up -d fingerprint-cassandra fingerprint-cassandra-init fingerprint-spark

docker compose exec -T fingerprint-spark /bin/bash -lc "\
  mkdir -p /tmp/.ivy2/cache /tmp/.ivy2/jars && \
  export SPARK_SUBMIT_OPTS='-Divy.cache.dir=/tmp/.ivy2/cache -Divy.home=/tmp/.ivy2' && \
  /opt/spark/bin/spark-submit \
    --master local[*] \
    --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.1 \
    /opt/spark-apps/analyze_logs.py $* \
"
